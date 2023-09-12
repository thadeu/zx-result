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

    def deconstruct
      [type, value]
    end

    def deconstruct_keys(_)
      { type: type, value: value, error: error }
    end

    def on_unknown(&block)
      __execute__(nil, &block)
    end

    def on_success(tag = nil, &block)
      return self if failure?

      __execute__(tag, &block)

      self
    end

    def on_failure(tag = nil, &block)
      return self if success?

      __execute__(tag, &block)

      self
    end

    def on(ontype, tag = nil, &block)
      case ontype.to_sym
      when :success then on_success(tag, &block)
      when :failure then on_failure(tag, &block)
      end
    end
    alias >> on
    alias | on
    alias pipe on

    def then(&block)
      fmap(&block)
    end

    def fmap(&block)
      return self if failure?

      new_value = block.call @value
      @value = new_value

      self
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

    def __execute__(tag = nil, &block)
      return block.call(@value, [@type, @success]) if tag.nil?

      block.call(@value, [@type, @success]) if @type == tag.to_sym
    end
    private :__execute__

    def Success(value = nil, options = {})
      success!(value, type: options.fetch(:type, :ok))
    end
    
    def Success!(value = nil, options = {})
      success!(value, type: options.fetch(:type, :ok))
    end

    def Failure(value = nil, options = {})
      failure!(value, type: options.fetch(:type, :error))
    end
    
    def Failure!(value = nil, options = {})
      failure!(value, type: options.fetch(:type, :error))
    end

    def self.Success(value = nil, options = {})
      new.success!(value, type: options.fetch(:type, :ok))
    end

    def self.Success!(...)
      Success(...)
    end

    def self.Failure(value = nil, options = {})
      new.failure!(value, type: options.fetch(:type, :error))
    end

    def self.Failure!(...)
      Failure(...)
    end

    Success = ->(*kwargs) { Success(*kwargs) }
    Failure = ->(*kwargs) { Failure(*kwargs) }
  end
end
