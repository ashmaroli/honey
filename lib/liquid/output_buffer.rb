# frozen_string_literal: true

module Liquid
  class OutputBuffer
    class BufferCache
      def self.cached_join(stack)
        @cached_join ||= {}
        @cached_join[stack.hash] ||= stack.join
      end
    end
    private_constant :BufferCache

    def initialize
      @stack = []
    end

    def <<(obj)
      @stack << obj
      self
    end

    def join
      BufferCache.cached_join(@stack)
    end

    def to_s
      @stack.to_s
    end

    def inspect
      @stack.inspect
    end
  end
end
