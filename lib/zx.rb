# frozen_string_literal: true

require 'zx/version'
require 'zx/fmap'
require 'zx/given'
require 'zx/reflect'
require 'zx/result'

module Zx
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
  rescue StandardError => e
    Failure[default || options.fetch(:or, nil)]
  end
end
