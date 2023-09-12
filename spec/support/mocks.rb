# frozen_string_literal: true

class AsComposition
  include Zx

  def pass(...)
    Success(...)
  end

  def passthrough(value)
    Success[value]
  end

  def failed(error)
    Failure[error, type: :error]
  end
end

class AsInherited < Zx::Result
  def pass(...)
    Success(...)
  end

  def passthrough(value)
    Success[value]
  end

  def failed(error)
    Failure(error, type: :error)
  end
end

module AsExtended
  extend self

  include Zx
  extend Zx

  def pass(...)
    Success(...)
  end

  def passthrough(value)
    Success[value]
  end

  def failed(error)
    Failure[error, type: :error]
  end
end
