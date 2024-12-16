# frozen_string_literal: true

module Zx
  module Core
    class Value
      def self.first(result)
        new.first(result)
      end

      def self.last(result)
        new.last(result)
      end

      def self.unwrap!(object)
        new.unwrap!(object)
      end

      def self.stack(object)
        new.stack(object, [])
      end

      def stack(object, list = [])
        if need_recursion? object
          list << object
          stack(object.value, list)
        end

        Array(list).flatten
      end

      def first(object)
        Array(stack(object)).flatten.first
      end

      def last(object)
        Array(stack(object)).flatten.last
      end

      def unwrap!(object)
        if need_recursion? object
          unwrap!(object.value)
        else
          object
        end
      end

      private

      def need_recursion?(object)
        Zx::Result === object && object.respond_to?(:value)
      end
    end
  end
end
