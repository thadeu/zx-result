# frozen_string_literal: true

class TaxService
  include Zx
end

class OrderService
  include Zx

  def initialize(tax: 0.1)
    @tax = tax
  end

  def apply(value)
    price = value + (value * @tax)

    return Failure[price, type: :priceless] if price < 100

    Success(price: price)
  end

  def apply_nested(value)
    price = value + (value * @tax)

    return Failure :priceless if price < 100

    Success(outside_price(price))
  end

  def outside_price(price)
    Success(outside_price_2(price), type: :price_1)
  end

  def outside_price_2(price)
    Success(outside_price_3(price), type: :price_2)
  end

  def outside_price_3(price)
    Success(price, type: :price_3)
  end
end
