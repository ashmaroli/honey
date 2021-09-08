# frozen_string_literal: true

module Liquid
  class VariableLookup
    SQUARE_BRACKETED = /\A\[(.*)\]\z/m
    COMMAND_METHODS = ['size', 'first', 'last'].freeze

    attr_reader :name, :lookups

    def self.parse(markup)
      new(markup)
    end

    def initialize(markup)
      lookups = markup.scan(VariableParser)

      name = lookups.shift
      name = Expression.parse(square_bracketed_str(name)) if name && square_bracketed?(name)

      @name = name

      @lookups = lookups
      @command_flags = 0

      @lookups.each_index do |i|
        lookup = lookups[i]
        if square_bracketed?(lookup)
          lookups[i] = Expression.parse(square_bracketed_str(lookup))
        elsif COMMAND_METHODS.include?(lookup)
          @command_flags |= 1 << i
        end
      end
    end

    def evaluate(context)
      name = context.evaluate(@name)
      object = context.find_variable(name)

      @lookups.each_index do |i|
        key = context.evaluate(@lookups[i])

        # If object is a hash- or array-like object we look for the
        # presence of the key and if its available we return it
        if object.respond_to?(:[]) &&
           ((object.respond_to?(:key?) && object.key?(key)) ||
            (object.respond_to?(:fetch) && key.is_a?(Integer)))

          # if its a proc we will replace the entry with the proc
          res = context.lookup_and_evaluate(object, key)
          object = res.to_liquid

          # Some special cases. If the part wasn't in square brackets and
          # no key with the same name was found we interpret following calls
          # as commands and call them on the current object
        elsif @command_flags & (1 << i) != 0 && object.respond_to?(key)
          object = object.send(key).to_liquid

          # No key was present with the desired value and it wasn't one of the directly supported
          # keywords either. The only thing we got left is to return nil or
          # raise an exception if `strict_variables` option is set to true
        else
          return nil unless context.strict_variables

          raise Liquid::UndefinedVariable, "undefined variable #{key}"
        end

        # If we are dealing with a drop here we have to
        object.context = context if object.respond_to?(:context=)
      end

      object
    end

    def ==(other)
      self.class == other.class && state == other.state
    end

    protected

    def state
      [@name, @lookups, @command_flags]
    end

    def square_bracketed?(str)
      str.start_with?('[') && str.end_with?(']')
    end
    private :square_bracketed?

    def square_bracketed_str(str)
      str.delete_prefix('[').delete_suffix!(']')
    end
    private :square_bracketed_str

    class ParseTreeVisitor < Liquid::ParseTreeVisitor
      def children
        @node.lookups
      end
    end
  end
end
