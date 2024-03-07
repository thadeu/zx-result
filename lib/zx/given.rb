# frozen_string_literal: true

module Zx
  class Given
    class FailureError < StandardError; end

    def initialize(input = nil)
      @original_input = input
      @input = input
      @success = true
      @exception = false
      @type = nil
    end

    attr_accessor :input, :type

    def error
      @input unless type == :ok
    end

    def success?
      !!@success
    end

    def failure?
      !success?
    end

    def and_then(&block)
      block.call(@input)

      self
    rescue StandardError => e
      @success = false
      @input = e.message
      @type = :error

      self
    end

    def and_then!(&block)
      self.class.new(block.call(@input))
    end

    def on_success(&block)
      return self if failure?

      and_then(&block)
    end

    def on_failure(&block)
      return self if success?

      and_then(&block)
    end

    def on(ontype, &block)
      case ontype.to_sym
      when :success then on_success(&block)
      when :failure then on_failure(&block)
      end
    end

    def unwrap
      @input
    end

    module Methods
      def Given(input)
        Given.new(input)
      end
    end
  end

  include Given::Methods
  extend Given::Methods
end
