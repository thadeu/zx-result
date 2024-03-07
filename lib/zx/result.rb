# frozen_string_literal: true

module Zx
  class Result
    class FailureError < StandardError; end

    def initialize
      @value = nil
      @success = true
      @exception = false
      @type = nil
    end

    attr_reader :value, :type

    def error
      @value unless type == :ok
    end

    def success?
      !!@success
    end

    def failure?
      !success?
    end

    def value!
      @value || raise(FailureError)
    end

    def unwrap
      @value
    end

    def deconstruct
      [type, value]
    end

    def deconstruct_keys(_)
      { type: type, value: value, error: error }
    end

    def on_unknown(&block)
      Reflect.apply(self, nil, &block)

      self
    end

    def on_success(tag = nil, &block)
      return self if failure?

      Reflect.apply(self, tag, &block)

      self
    end

    def on_failure(tag = nil, &block)
      return self if success?

      Reflect.apply(self, tag, &block)

      self
    end

    def on(ontype, tag = nil, &block)
      case ontype.to_sym
      when :success then on_success(tag, &block)
      when :failure then on_failure(tag, &block)
      when :unknown then on_unknown(tag, &block)
      end
    end
    alias >> on
    alias | on
    alias pipe on

    def then(&block)
      Fmap.call(self, &block)
    end
    alias and_then then
    alias step then
    alias fmap then

    def check(&block)
      return self if !!block.call(@value)

      failure!
    end

    def failure!(value = nil, type: :error)
      @type = type.to_sym
      @success = false
      @value = value

      self
    end

    def success!(value = nil, type: :ok)
      @type = type.to_sym
      @success = true
      @value = value

      self
    end

    include Mixin
    extend Mixin
  end

  include Mixin
  extend Mixin
end
