# frozen_string_literal: true

module Zx
  class Match
    attr_reader :fn, :result

    def initialize(result:, **kwargs)
      @result = result
      @fn = result.failure? ? kwargs[:Err] : kwargs[:Ok]
    end

    def check!
      return fn.call(result.error, result.type) if result.failure?

      case Parameter.arity(fn)
      when 0 then fn.call
      when 1 then fn.call(result.value)
      when 2 then fn.call(result.value, result.type)
      end
    end
  end
end
