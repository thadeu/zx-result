# frozen_string_literal: true

module Zx
  class Reflect
    def self.apply(result, tag, &block)
      new(result, tag).apply(&block)
    end

    attr_reader :stack, :tag

    def initialize(stack, tag)
      @stack = stack
      @tag = tag
    end

    def apply(&block)
      return if !tag.nil? && stack.type != tag.to_sym

      reflect_callable(&block)
      push_to_executed(block)
    end

    def push_to_executed(block)
      stack.executed << block
    end
    private :push_to_executed

    def reflect_callable(&block)
      block.call(stack.unwrap, [stack.type, stack.success?])
    end
    private :reflect_callable
  end
end
