# frozen_string_literal: true

module Liquid
  class Document < BlockBody
    def self.parse(tokens, parse_context)
      doc = new
      doc.parse(tokens, parse_context)
      doc
    end

    def parse(tokens, parse_context)
      super do |end_tag_name, end_tag_params|
        unknown_tag(end_tag_name, parse_context) if end_tag_name
      end
    rescue SyntaxError => e
      e.line_number ||= parse_context.line_number
      raise
    end

    def unknown_tag(tag, _parse_context)
      case tag
      when 'else', 'end'
        raise SyntaxError, "Unexpected outer '#{tag}' tag"
      else
        raise SyntaxError, "Unknown tag '#{tag}'"
      end
    end
  end
end
