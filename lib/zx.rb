# frozen_string_literal: true

require 'zx/version'
require 'zx/core'
require 'zx/core/util/parameter'
require 'zx/core/base'
require 'zx/core/and_then'
require 'zx/core/caller'
require 'zx/core/match'
require 'zx/core/stack'
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
      Zx::Result.new.success!(value, options).last
    end

    def Failure(value = nil, options = {})
      Zx::Result.new.failure!(value, options).last
    end

    def Try(input = nil, options = {})
      if block_given?
        Success(yield, options)
      else
        Success(input, options)
      end
    rescue StandardError => _e
      Failure(nil || options.delete(:or), options)
    end

    def Given(input = nil, options = {}, &block)
      Try(input, options, &block)
    end
  end

  include Methods
  extend Methods
end
