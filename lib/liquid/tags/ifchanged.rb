# frozen_string_literal: true

module Liquid
  class Ifchanged < Block
    def render(context)
      context.stack do
        output = super

        if output == context.registers[:ifchanged]
          ''
        else
          context.registers[:ifchanged] = output
          output
        end
      end
    end
  end

  Template.register_tag('ifchanged', Ifchanged)
end
