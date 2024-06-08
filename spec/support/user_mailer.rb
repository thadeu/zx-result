# frozen_string_literal: true

require 'zx'

class UserMailer
  include Zx

  Passthru = ->(input) { input }

  def deliver(input)
    Given(input)
      .and_then(&Passthru)
  end
end
