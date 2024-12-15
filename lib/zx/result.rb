# frozen_string_literal: true

module Zx
  class Result
    class FailureError < StandardError; end

    def initialize
      @success = true
    end

    attr_reader :type, :value

    def executed
      @executed ||= Set.new
    end

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
      @value || raise(FailureError, 'value is empty')
    end

    def unwrap
      if @value.is_a?(Result)
        @value = @value.value
        unwrap
      else
        @value
      end
    end
    alias to_s unwrap

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
    alias pipe on

    def match(**kwargs)
      Match.new(result: self, **kwargs).check!
    end

    def otherwise(&block)
      return if executed.size.positive?

      Reflect.apply(self, nil, &block)
    end

    def then(&block)
      return self if failure?

      caller_value = Caller.get(block, value)
      @value = Value.deepth(caller_value)

      Value.deepth(self)
    end
    alias and_then then
    alias step then
    alias fmap then

    def check(&block)
      return self if !!block[@value]

      failure!
    end

    def failure!(fvalue = nil, options = { type: :error })
      options = extracted_options(options)

      @type = (options&.delete(:type) || :error)&.to_sym
      @success = false
      @value = fvalue

      Value.deepth(self)
    end

    def success!(svalue = nil, options = {})
      options = extracted_options(options)

      @type = (options&.delete(:type) || :ok).to_sym
      @success = true
      @value = svalue

      Value.deepth(self)
    end

    def extracted_options(options)
      if options.is_a?(Hash)
        options
      elsif options.is_a?(Symbol)
        { type: options }
      end
    end
  end
end
