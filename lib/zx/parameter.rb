# frozen_string_literal: true

module Zx
  module Parameter
    extend self

    def self.arity?(object)
      object.arity != 0
    end

    def self.kwargs?(object)
      object.parameters.map(&:first).all?(/\Akey/)
    end
  end
end
