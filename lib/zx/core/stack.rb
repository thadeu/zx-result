# frozen_string_literal: true

module Zx
  module Core
    class Stack
      def self.first(result)
        new.first(result)
      end

      def self.last(result)
        new.last(result)
      end

      def self.unwrap!(object)
        new.unwrap!(object)
      end

      def self.nodes(object)
        new.stack(object, [])
      end

      def nodes(object, list = [])
        if need_recursion? object
          list << object
          nodes(object.value, list)
        end

        Array(list).flatten
      end

      def first(object)
        Array(nodes(object)).flatten.first
      end

      def last(object)
        Array(nodes(object)).flatten.last
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
