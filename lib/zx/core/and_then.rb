# frozen_string_literal: true

module Zx
  module Core
    class AndThen
      def self.spawn(result, &block)
        new(result).spawn!(&block)
      end

      attr_reader :result

      def initialize(result)
        @result = result
      end

      def spawn!(&block)
        lastly = Core::Value.last(result)

        success = result.success?
        type = result.type

        if lastly.failure?
          success = false
          type = lastly.type
          value = lastly.value

          return [value, type, success]
        end

        value = Core::Caller.get(lastly.unwrap, &block)

        if value.is_a?(Zx::Result)
          success = value.success?
          type = value.type
          value = value.unwrap
        end

        [value, type, success]
      end
    end
  end
end
