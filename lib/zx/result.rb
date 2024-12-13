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

    attr_accessor :value

    def error
      @value unless success?
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

    def type
      @type
    end

    def unwrap
      if @value.is_a?(Zx::Result)
        @value = @value.value
        unwrap
      else
        @value
      end
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

    def then(method_name = nil, &block)
      return self if failure?

      caller_value = Caller.get(block, value)
      @value = Value.deepth(caller_value)

      Value.deepth(self)
    end
    alias and_then then
    alias step then
    alias fmap then

    def check(&block)
      return self if !!block.call(@value)

      failure!
    end

    def failure!(fvalue = nil, options = { type: :error })
      options = if options.is_a?(Hash)
                  options
                elsif options.is_a?(Symbol)
                  { type: options }
                end

      @type = options&.fetch(:type, nil)&.to_sym || :error
      @success = false
      @value = fvalue

      self
    end

    def success!(svalue = nil, options = {})
      options = if options.is_a?(Hash)
                  options
                elsif options.is_a?(Symbol)
                  { type: options }
                end

      @type = (options&.delete(:typo) || options&.delete(:_type) || options&.delete(:type) || :ok).to_sym
      @success = true
      @value = svalue

      self
    end
  end
end
