# frozen_string_literal: true

require_relative 'core'

module Zx
  class Result < Core::Base
    class FailureError < StandardError; end

    def value!
      last&.value || raise(FailureError, 'value is empty')
    end

    def first
      Core::Stack.first(self) || self
    end

    def last
      Core::Stack.last(self) || self
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
      return self if executed.size.positive?

      Reflect.apply(self, nil, &block)

      self
    end

    def then(method_name = nil, *_pargs, &block)
      @value, @type, @success = Core::AndThen.spawn(
        self,
        method_name,
        &block
      )

      self
    end
    alias and_then then
    alias step then
    alias fmap then

    def check(tag = nil, &block)
      return self if !!block[@value]

      failure!(nil, { type: tag || :error })
    end

    def failure!(fvalue = nil, options = { type: :error })
      options = extracted_options!(options)

      @type = (options&.delete(:type) || :error)&.to_sym
      @success = false
      @value = fvalue
      @ctx = options.delete(:ctx) if @ctx.nil?

      self
    end

    def success!(svalue = nil, options = {})
      options = extracted_options!(options)

      @type = (options&.delete(:type) || :ok).to_sym
      @success = true
      @value = svalue
      @ctx = options.delete(:ctx)

      self
    end

    def inspect
      format(
        '#<%<name>s success=%<success>s type=%<type>p value=%<value>p>',
        name: self.class.name,
        success: last.success?,
        type: last.type,
        value: last.unwrap
      )
    end
    alias to_s inspect
  end
end
