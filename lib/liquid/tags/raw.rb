# frozen_string_literal: true

module Liquid
  class Raw < Block
    Syntax = /\A\s*\z/
    FullTokenPossiblyInvalid = /\A(.*)#{TagStart}\s*(\w+)\s*(.*)?#{TagEnd}\z/om

    def initialize(tag_name, markup, parse_context)
      super

      ensure_valid_markup(tag_name, markup, parse_context)
    end

    def parse(tokens)
      @body = +''
      while token = tokens.shift
        if token =~ FullTokenPossiblyInvalid
          @body << Regexp.last_match(1) if Regexp.last_match(1) != ""
          return if block_delimiter == Regexp.last_match(2)
        end
        @body << token unless token.empty?
      end

      raise SyntaxError, "'#{block_name}' tag was never closed"
    end

    def render(_context)
      @body
    end

    def nodelist
      [@body]
    end

    def blank?
      @body.empty?
    end

    protected

    def ensure_valid_markup(tag_name, markup, _parse_context)
      raise SyntaxError, "Syntax Error in '#{tag_name}' - Valid syntax: #{tag_name}" unless Syntax.match?(markup)
    end
  end

  Template.register_tag('raw', Raw)
end
