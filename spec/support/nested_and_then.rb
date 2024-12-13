# frozen_string_literal: true

class NestedAndThen
  include Zx

  def call_ok_hash(input)
    Try(input)
      .and_then(&method(:ok1_return_hash))
      .and_then(&method(:ok2_hash))
  end

  def call_ok_kw
    Try(self)
      .and_then(&method(:ok1_return_kw))
      .and_then(&method(:ok2_kw))
  end

  def call_failure1
    Try(self)
      .and_then(&method(:ok1))
      .and_then(&method(:failure1))
      .and_then(&method(:failure2))
      .and_then(&method(:ok2))
      .unwrap
  end

  def call_failure2
    Try(self)
      .and_then(&method(:failure2))
      .and_then(&method(:ok1))
      .and_then(&method(:ok2))
      .and_then(&method(:failure1))
      .unwrap
  end

  def failure1(*)
    Failure(Failure(Failure('error 1', :error1), :error1), :error1)
  end

  def failure2(*) = Failure('error 2', type: :error2)

  def ok1 = Success(1, type: :ok)

  def ok2 = Success(1, type: :ok)

  def ok1_return_hash = Success({ above: 1 })

  def ok1_return_kw = Success(above: 1)

  def ok2_kw(above:)
    if above == 1
      Success(2, type: :continue)
    else
      Success(3, type: :continue)
    end
  end

  def ok2_hash(opts = {})
    if opts[:above] == 1
      Success(2, type: :continue)
    else
      Success(3, type: :continue)
    end
  end
end
