# frozen_string_literal: true

module Zx
  class Reflect
    attr_reader :result, :tag

    def initialize(result, tag)
      @result = result
      @tag = tag
    end

    def apply(&block)
      case tag
      when Symbol, String
        return if result.type != tag.to_sym

        block.call(result.unwrap, [result.type, result.success?])
        result.executed << block
      end
    end

    def self.apply(result, tag, &block)
      new(result, tag).apply(&block)
    end
  end
end
