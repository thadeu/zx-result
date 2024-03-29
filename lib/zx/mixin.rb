# frozen_string_literal: true

module Zx
  module Mixin
    Success = ->(value = nil, options = {}) { Zx::Result.new.success!(value, options) }
    Failure = ->(value = nil, options = {}) { Zx::Result.new.failure!(value, options) }

    def Success(value = nil, options = {})
      Zx::Result.new.success!(value, type: options.fetch(:type, :ok))
    end

    def Failure(value = nil, options = {})
      Zx::Result.new.failure!(value, type: options.fetch(:type, :error))
    end

    def Try(default = nil, options = {})
      Success[yield]
    rescue StandardError => e
      Failure[default || options.fetch(:or, nil)]
    end
  end
end
