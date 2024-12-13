# frozen_string_literal: true

module Zx
  module Caller
    extend self

    def get(blk, value)
      return blk.call unless Parameter.arity?(blk)
      return blk.call(**value) if Parameter.kwargs?(blk)

      blk.call(value)
    end
  end
end
