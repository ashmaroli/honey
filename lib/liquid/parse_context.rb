# frozen_string_literal: true

module Liquid
  class ParseContext
    attr_accessor :line_number, :trim_whitespace, :depth
    attr_reader :partial, :warnings, :error_mode

    def initialize(options = {})
      @options = options
      @warnings = []
      @depth = 0
      @partial = false
      @error_mode = options[:error_mode] || Template.error_mode
    end

    def [](option_key)
      @options[option_key]
    end
  end
end
