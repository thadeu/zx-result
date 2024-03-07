# frozen_string_literal: true

require 'zx/eager_load'

class UserMailer
  Passthru = ->(input) { input }

  def deliver(input)
    Given(input)
      .and_then(&Passthru)
  end
end
