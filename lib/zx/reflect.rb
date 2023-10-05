# frozen_string_literal: true

module Zx
  class Reflect
    attr_accessor :result, :tag

    def initialize(result, tag)
      self.result = result
      self.tag = tag
    end

    def apply(&block)
      return block.call(result.value, [result.type, result.success?]) if tag.nil?

      block.call(result.value, [result.type, result.success?]) if result.type == tag.to_sym
    end

    def self.apply(result, tag, &block)
      new(result, tag).apply(&block)
    end
  end
end
