# frozen_string_literal: true

class OrderService
  include Zx

  def initialize(tax: 0.1)
    @tax = tax
  end

  def apply(value)
    price = value + (value * @tax)

    return Failure :priceless if price < 100

    Success price: price
  end
end
