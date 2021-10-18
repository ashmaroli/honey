# frozen_string_literal: true

module Liquid
  # "For" iterates over an array or collection.
  # Several useful variables are available to you within the loop.
  #
  # == Basic usage:
  #
  #    {% for item in collection %}
  #      {{ forloop.index }}: {{ item.name }}
  #    {% endfor %}
  #
  # == Advanced usage:
  #
  #    {% for item in collection %}
  #      <div {% if forloop.first %}class="first"{% endif %}>
  #        Item {{ forloop.index }}: {{ item.name }}
  #      </div>
  #    {% else %}
  #      There is nothing in the collection.
  #    {% endfor %}
  #
  # You can also define a limit and offset much like SQL.  Remember
  # that offset starts at 0 for the first item.
  #
  #    {% for item in collection limit:5 offset:10 %}
  #      {{ item.name }}
  #    {% end %}
  #
  # To reverse the for loop simply use
  #
  #    {% for item in collection reversed %}
  #
  # (note that the flag's spelling is different to the filter `reverse`)
  #
  #
  # == Available variables:
  #
  #       forloop.name :: 'item-collection'
  #     forloop.length :: Length of the loop
  #      forloop.index :: The current item's position in the collection;
  #                         forloop.index starts at 1.
  #                         This is helpful for non-programmers who believe the first item in
  #                         an array is 1, not 0.
  #     forloop.index0 :: The current item's position in the collection where the first item is 0
  #     forloop.rindex :: Number of items remaining in the loop;
  #                         (length - index) where 1 is the last item.
  #    forloop.rindex0 :: Number of items remaining in the loop where 0 is the last item.
  #      forloop.first :: Returns true if current item is the first item.
  #       forloop.last :: Returns true if current item is the last item.
  # forloop.parentloop :: Provides access to the parent loop, if present.
  #
  class For < Block
    Syntax = /\A(#{VariableSegment}+)\s+in\s+(#{QuotedFragment}+)\s*(reversed)?/o

    attr_reader :collection_name, :variable_name, :limit, :from

    def initialize(tag_name, markup, options)
      super
      @from = @limit = nil
      parse_with_selected_parser(markup)
      @for_block  = BlockBody.new
      @else_block = nil
    end

    def parse(tokens)
      parse_body(@else_block, tokens) if parse_body(@for_block, tokens)
    end

    def nodelist
      @else_block ? [@for_block, @else_block] : [@for_block]
    end

    def unknown_tag(tag, markup, tokens)
      return super unless tag == 'else'

      @else_block = BlockBody.new
    end

    def render(context)
      offsets = context.registers[:for] ||= {}

      collection = context.evaluate(@collection_name)
      collection = collection.to_a if collection.is_a?(Range)

      from = case @from
             when nil       then 0
             when :continue then offsets[@name].to_i
             else
               context.evaluate(@from).to_i
             end

      to = (context.evaluate(@limit).to_i + from) if @limit

      segment = Utils.slice_collection(collection, from, to)
      segment.reverse! if @reversed

      offsets[@name] = from + segment.length

      if segment.empty?
        @else_block ? @else_block.render(context) : ''
      else
        render_segment(context, segment)
      end
    end

    protected

    def lax_parse(markup)
      raise SyntaxError, "Syntax Error in 'for loop' - Valid syntax: for [item] in [collection]" unless markup =~ Syntax

      @variable_name  = Regexp.last_match(1)
      collection_name = Regexp.last_match(2)
      @reversed       = !!Regexp.last_match(3)

      @name = "#{@variable_name}-#{collection_name}"
      @collection_name = Expression.parse(collection_name)

      markup.scan(TagAttributes) do |key, value|
        set_attribute(key, value)
      end
    end

    def strict_parse(markup)
      p = Parser.new(markup)
      @variable_name = p.consume(:id)
      raise SyntaxError, "For loops require an 'in' clause" unless p.id?('in')

      collection_name = p.expression
      @name = "#{@variable_name}-#{collection_name}"
      @collection_name = Expression.parse(collection_name)
      @reversed = p.id?('reversed')

      while p.look(:id) && p.look(:colon, 1)
        attribute = p.id?('limit') || p.id?('offset')
        raise SyntaxError, "Invalid attribute in for loop. Valid attributes are limit and offset" unless attribute

        p.consume
        set_attribute(attribute, p.expression)
      end
      p.consume(:end_of_string)
    end

    private

    def render_segment(context, segment)
      for_stack = context.registers[:for_stack] ||= []
      length = segment.length

      result = []

      context.stack do
        loop_vars = Liquid::ForloopDrop.new(@name, length, for_stack[-1])
        for_stack.push(loop_vars)

        begin
          context['forloop'] = loop_vars

          segment.each do |item|
            context[@variable_name] = item
            result << @for_block.render(context)
            loop_vars.send(:increment!)

            # Handle any interrupts if they exist.
            next unless context.interrupt?

            case context.pop_interrupt
            when BreakInterrupt    then break
            when ContinueInterrupt then next
            end
          end
        ensure
          for_stack.pop
        end
      end

      result.join
    end

    def set_attribute(key, expr)
      case key
      when 'offset'
        @from = expr == 'continue' ? :continue : Expression.parse(expr)
      when 'limit'
        @limit = Expression.parse(expr)
      end
    end

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        (super + [@node.limit, @node.from, @node.collection_name]).compact
      end
    end
  end

  Template.register_tag('for', For)
end
