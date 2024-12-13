# frozen_string_literal: true

module Zx
  module Value
    extend self

    def deepth(object)
      return object unless object.respond_to?(:value)
      return deepth(object.value) if object.value.is_a?(Result)

      object
    end
  end
end
