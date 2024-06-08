# frozen_string_literal: true

require 'zx/version'
require 'zx/fmap'
require 'zx/reflect'
require 'zx/result'

module Zx
  class AbortError < ::RuntimeError
    attr_reader :type

    def initialize(message: nil, type: :error)
      @type = type
      super(message)
    end
  end

  module Methods
    Success = ->(value = nil, options = {}) { Zx.Success(value, { type: :ok }.merge(options)) }
    Failure = ->(value = nil, options = {}) { Zx.Failure(value, { type: :error }.merge(options)) }

    def Success(value = nil, options = {})
      Zx::Result.new.success!(value, type: options.fetch(:type, :ok))
    end

    def Failure(value = nil, options = {})
      Zx::Result.new.failure!(value, type: options.fetch(:type, :error))
    end

    def Try(default = nil, options = {})
      Success[yield]
    rescue StandardError => _e
      Failure[default || options.fetch(:or, nil)]
    end

    def Given(input)
      Try { input }
    end
  end

  include Methods
  extend Methods
end
