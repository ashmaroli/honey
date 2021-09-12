# frozen_string_literal: true

module Liquid
  class Error < ::StandardError
    attr_accessor :line_number, :template_name, :markup_context

    def to_s(with_prefix = true)
      parts = []
      parts << message_prefix if with_prefix
      parts << super()
      parts << " " << markup_context if markup_context
      parts.join
    end

    private

    def message_prefix
      parts = []
      parts << (is_a?(SyntaxError) ? "Liquid syntax error" : "Liquid error")

      if line_number
        parts << " ("
        parts << template_name << " " if template_name
        parts << "line " << line_number << ")"
      end

      parts << ": "
      parts.join
    end
  end

  ArgumentError       = Class.new(Error)
  ContextError        = Class.new(Error)
  FileSystemError     = Class.new(Error)
  StandardError       = Class.new(Error)
  SyntaxError         = Class.new(Error)
  StackLevelError     = Class.new(Error)
  TaintedError        = Class.new(Error)
  MemoryError         = Class.new(Error)
  ZeroDivisionError   = Class.new(Error)
  FloatDomainError    = Class.new(Error)
  UndefinedVariable   = Class.new(Error)
  UndefinedDropMethod = Class.new(Error)
  UndefinedFilter     = Class.new(Error)
  MethodOverrideError = Class.new(Error)
  InternalError       = Class.new(Error)
end
