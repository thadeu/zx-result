# frozen_string_literal: true

class TaxService
  include Zx
end

class InsideTaxService
  extend Zx

  def self.outside_price_3(price)
    Success(price + 1, type: :price_3)
  end
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

    return Failure(0, type: :priceless_0) if price < 100

    Success(outside_price_1(price), type: :price_0)
  end

  def outside_price_1(price)
    if outside_price_2(price).unwrap < 200
      return Failure(0, :priceless_1)
    end

    Success(outside_price_2(price), type: :price_1)
  end

  def outside_price_2(price)
    Failure(outside_price_3(price+1), type: :price_2)
  end

  def outside_price_3(price)
    InsideTaxService.outside_price_3(price)
  end
end
