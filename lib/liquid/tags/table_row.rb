# frozen_string_literal: true

module Liquid
  class TableRow < Block
    Syntax = /(\w+)\s+in\s+(#{QuotedFragment}+)/o

    attr_reader :variable_name, :collection_name, :attributes

    def initialize(tag_name, markup, options)
      super
      if markup =~ Syntax
        @variable_name = Regexp.last_match(1)
        @collection_name = Expression.parse(Regexp.last_match(2))
        @attributes = {}
        markup.scan(TagAttributes) do |key, value|
          @attributes[key] = Expression.parse(value)
        end
      else
        raise SyntaxError, "Syntax Error in 'table_row loop' - Valid syntax: table_row [item] in [collection] cols=3"
      end
    end

    def render(context)
      collection = context.evaluate(@collection_name) or return ''

      from = @attributes.key?('offset') ? context.evaluate(@attributes['offset']).to_i : 0
      to = @attributes.key?('limit') ? from + context.evaluate(@attributes['limit']).to_i : nil

      collection = Utils.slice_collection(collection, from, to)

      length = collection.length

      cols = context.evaluate(@attributes['cols']).to_i

      result = OutputBuffer.new
      result << "<tr class=\"row1\">\n"
      context.stack do
        tablerowloop = Liquid::TablerowloopDrop.new(length, cols)
        context['tablerowloop'] = tablerowloop

        collection.each do |item|
          context[@variable_name] = item

          result << "<td class=\"col#{tablerowloop.col}\">"
          result << super
          result << '</td>'

          if tablerowloop.col_last && !tablerowloop.last
            result << "</tr>\n<tr class=\"row#{tablerowloop.row + 1}\">"
          end

          tablerowloop.send(:increment!)
        end
      end
      result << "</tr>\n"
      result.join
    end

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        super + @node.attributes.values + [@node.collection_name]
      end
    end
  end

  Template.register_tag('tablerow', TableRow)
end
