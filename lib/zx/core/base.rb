# frozen_string_literal: true

module Zx
  module Core
    class Base
      attr_reader :ctx

      def initialize
        @success = true
        @type = :ok
        @value = nil
      end

      def deconstruct
        [type, unwrap]
      end

      def deconstruct_keys(_)
        { type: type, value: unwrap, error: error }
      end

      def executed
        @executed ||= ::Set.new
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
        raise NotImplementedError
      end

      def unwrap
        last.value
      end

      def first
        raise NotImplementedError
      end

      def last
        raise NotImplementedError
      end

      def extracted_options!(opts)
        return opts if opts.is_a?(Hash)

        { type: opts } if opts.is_a?(Symbol)
      end
      private :extracted_options!
    end
  end
end
