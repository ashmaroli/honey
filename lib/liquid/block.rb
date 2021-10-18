# frozen_string_literal: true

module Liquid
  class Block < Tag
    MAX_DEPTH = 100

    def initialize(tag_name, markup, options)
      super
      @blank = true
    end

    def parse(tokens)
      @body = BlockBody.new
      while parse_body(@body, tokens)
      end
    end

    def render(context)
      @body.render(context)
    end

    def blank?
      @blank
    end

    def nodelist
      @body.nodelist
    end

    def unknown_tag(tag, _params, _tokens)
      if tag == 'else'
        raise SyntaxError, "#{block_name} tag does not expect 'else' tag"
      elsif tag.start_with?('end')
        raise SyntaxError, "'#{tag}' is not a valid delimiter for #{block_name} tags. use #{block_delimiter}"
      else
        raise SyntaxError, "Unknown tag '#{tag}'"
      end
    end

    def block_name
      @tag_name
    end

    def block_delimiter
      @block_delimiter ||= "end#{block_name}"
    end

    protected

    def parse_body(body, tokens)
      raise StackLevelError, "Nesting too deep" if parse_context.depth >= MAX_DEPTH

      parse_context.depth += 1
      begin
        body.parse(tokens, parse_context) do |end_tag_name, end_tag_params|
          @blank &&= body.blank?

          return false if end_tag_name == block_delimiter
          raise SyntaxError, "'#{block_name}' tag was never closed" unless end_tag_name

          # this tag is not registered with the system
          # pass it to the current block for special handling or error reporting
          unknown_tag(end_tag_name, end_tag_params, tokens)
        end
      ensure
        parse_context.depth -= 1
      end

      true
    end
  end
end
