# frozen_string_literal: true

require 'zx/result'

module Zx
  module Extendable
    Success = ->(*kwargs) { Result.Success(*kwargs) }
    Failure = ->(*kwargs) { Result.Failure(*kwargs) }

    def Success(...)
      Result.Success(...)
    end

    def Failure(...)
      Result.Failure(...)
    end
  end

  include Extendable
  extend Extendable
end
