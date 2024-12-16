# frozen_string_literal: true

module Zx
  module Core
    module Caller
      extend self

      def get(value, &block)
        return block.call unless Util::Parameter.arity?(block)
        return block.call(**value) if Util::Parameter.kwargs?(block)

        block.call(value)
      end
    end
  end
end
