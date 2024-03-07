# frozen_string_literal: true

module Zx
  module Fmap
    def self.call(result, &block)
      return result if result.failure?

      new_value = block.call result.value
      result.instance_variable_set(:@value, new_value)

      result
    end
  end
end
