# frozen_string_literal: true

module Zx
  class Result
    class FailureError < StandardError; end

    def initialize
      @success = true
    end

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

    def type
      @type ||= last.type
    end

    def value
      @value || nil
    end

    def value!
      unwrap || raise(FailureError, 'value is empty')
    end

    def unwrap
      last.value
    end

    def last
      Core::Stack.last(self) || self
    end

    def first
      Core::Stack.first(self) || self
    end

    def inspect
      format(
        '#<%<class_name>s success=%<success>s type=%<type>p value=%<value>p>',
        class_name: self.class.name,
        success: last.success?,
        type: last.type,
        value: last.unwrap
      )
    end
    alias to_s inspect

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
      Core::Match.new(result: self, **kwargs).check!
    end

    def otherwise(&block)
      return if executed.size.positive?

      Reflect.apply(self, nil, &block)
    end

    def then(&block)
      @value, @type, @success = Core::AndThen.spawn(self, &block)

      self
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

      self
    end

    def success!(svalue = nil, options = {})
      options = extracted_options(options)

      @type = (options&.delete(:type) || :ok).to_sym
      @success = true
      @value = svalue

      self
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
