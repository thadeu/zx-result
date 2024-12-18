# frozen_string_literal: true

module Zx
  module Core
    class AndThen
      def self.spawn(result, method_name = nil, &block)
        new(result).spawn!(method_name, &block)
      end

      attr_reader :result

      def initialize(result)
        @result = result
      end

      def spawn!(method_name = nil, &block)
        lastly = Core::Stack.last(result)

        unless block_given?
          first = Core::Stack.first(result)
          block = first&.ctx.method(method_name) if first&.ctx
        end

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
