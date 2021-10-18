# frozen_string_literal: true

module Liquid
  class Case < Block
    Syntax     = /(#{QuotedFragment})/o
    WhenSyntax = /(#{QuotedFragment})(?:(?:\s+or\s+|\s*,\s*)(#{QuotedFragment}.*))?/om

    attr_reader :blocks, :left

    def initialize(tag_name, markup, options)
      super
      @blocks = []

      if markup =~ Syntax
        @left = Expression.parse(Regexp.last_match(1))
      else
        raise SyntaxError, "Syntax Error in 'case' - Valid syntax: case [condition]"
      end
    end

    def parse(tokens)
      body = BlockBody.new
      body = @blocks.last.attachment while parse_body(body, tokens)
    end

    def nodelist
      @blocks.map(&:attachment)
    end

    def unknown_tag(tag, markup, tokens)
      case tag
      when 'when'
        record_when_condition(markup)
      when 'else'
        record_else_condition(markup)
      else
        super
      end
    end

    def render(context)
      context.stack do
        execute_else_block = true

        output = []
        @blocks.each do |block|
          if block.else?
            return block.attachment.render(context) if execute_else_block
          elsif block.evaluate(context)
            execute_else_block = false
            output << block.attachment.render(context)
          end
        end
        output.join
      end
    end

    private

    def record_when_condition(markup)
      body = BlockBody.new

      while markup
        unless markup =~ WhenSyntax
          raise SyntaxError,
                "Syntax Error in tag 'case' - Valid when condition: {% when [condition] [or condition2...] %}"
        end

        markup = Regexp.last_match(2)

        block = Condition.new(@left, '==', Expression.parse(Regexp.last_match(1)))
        block.attach(body)
        @blocks << block
      end
    end

    def record_else_condition(markup)
      unless markup.strip.empty?
        raise SyntaxError, "Syntax Error in tag 'case' - Valid else condition: {% else %} (no parameters) "
      end

      block = ElseCondition.new
      block.attach(BlockBody.new)
      @blocks << block
    end

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        [@node.left] + @node.blocks
      end
    end
  end

  Template.register_tag('case', Case)
end
