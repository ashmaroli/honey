# frozen_string_literal: true

module Liquid
  # Cycle is usually used within a loop to alternate between values, like colors or DOM classes.
  #
  #   {% for item in items %}
  #     <div class="{% cycle 'red', 'green', 'blue' %}"> {{ item }} </div>
  #   {% end %}
  #
  #    <div class="red"> Item one </div>
  #    <div class="green"> Item two </div>
  #    <div class="blue"> Item three </div>
  #    <div class="red"> Item four </div>
  #    <div class="green"> Item five</div>
  #
  class Cycle < Tag
    SimpleSyntax = /\A#{QuotedFragment}+/o
    NamedSyntax  = /\A(#{QuotedFragment})\s*:\s*(.*)/om

    attr_reader :variables

    def initialize(tag_name, markup, options)
      super
      case markup
      when NamedSyntax
        @variables = variables_from_string(Regexp.last_match(2))
        @name = Expression.parse(Regexp.last_match(1))
      when SimpleSyntax
        @variables = variables_from_string(markup)
        @name = @variables.to_s
      else
        raise SyntaxError, "Syntax Error in 'cycle' - Valid syntax: cycle [name :] var [, var2, var3 ...]"
      end
    end

    def render(context)
      context.registers[:cycle] ||= {}

      context.stack do
        key = context.evaluate(@name)
        iteration = context.registers[:cycle][key].to_i
        result = context.evaluate(@variables[iteration])
        iteration += 1
        iteration  = 0 if iteration >= @variables.size
        context.registers[:cycle][key] = iteration
        result
      end
    end

    private

    def variables_from_string(markup)
      markup.split(',').collect do |var|
        var =~ /\s*(#{QuotedFragment})\s*/o
        Regexp.last_match(1) ? Expression.parse(Regexp.last_match(1)) : nil
      end.compact
    end

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        Array(@node.variables)
      end
    end
  end

  Template.register_tag('cycle', Cycle)
end
