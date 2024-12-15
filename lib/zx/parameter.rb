# frozen_string_literal: true

module Zx
  module Parameter
    extend self

    def self.arity(object)
      if object.respond_to?(:arity)
        object.arity
      elsif object.respond_to?(:call)
        object.method(:call).parameters.size
      else
        0
      end
    end

    def self.arity?(object)
      arity(object) != 0
    end

    def self.kwargs?(object)
      object.parameters.map(&:first).all?(/\Akey/)
    end
  end
end
