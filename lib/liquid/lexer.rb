# frozen_string_literal: true

require "strscan"
module Liquid
  class Lexer
    SPECIALS = {
      '|' => :pipe,
      '.' => :dot,
      ':' => :colon,
      ',' => :comma,
      '[' => :open_square,
      ']' => :close_square,
      '(' => :open_round,
      ')' => :close_round,
      '?' => :question,
      '-' => :dash
    }.freeze
    IDENTIFIER = /[a-zA-Z_][\w-]*\??/
    SINGLE_STRING_LITERAL = /'[^']*'/
    DOUBLE_STRING_LITERAL = /"[^"]*"/
    NUMBER_LITERAL = /-?\d+(\.\d+)?/
    DOTDOT = /\.\./
    COMPARISON_OPERATOR = /==|!=|<>|<=?|>=?|contains(?=\s)/
    WHITESPACE_OR_NOTHING = /\s*/

    def initialize(input)
      @ss = StringScanner.new(input)
    end

    def tokenize
      @output = []

      until @ss.eos?
        @ss.skip(WHITESPACE_OR_NOTHING)
        break if @ss.eos?

        tok = \
          case
          when t = @ss.scan(COMPARISON_OPERATOR)   then [:comparison, t]
          when t = @ss.scan(SINGLE_STRING_LITERAL) then [:string, t]
          when t = @ss.scan(DOUBLE_STRING_LITERAL) then [:string, t]
          when t = @ss.scan(NUMBER_LITERAL)        then [:number, t]
          when t = @ss.scan(IDENTIFIER)            then [:id, t]
          when t = @ss.scan(DOTDOT)                then [:dotdot, t]
          else
            c = @ss.getch
            if s = SPECIALS[c]
              [s, c]
            else
              raise SyntaxError, "Unexpected character #{c}"
            end
          end
        @output << tok
      end

      @output << [:end_of_string]
    end
  end
end
