# frozen_string_literal: true

module Liquid
  class Comment < Block
    def render(_context)
      ''
    end

    def unknown_tag(_tag, _markup, _tokens)
    end

    def blank?
      true
    end
  end

  Template.register_tag('comment', Comment)
end
