# frozen_string_literal: true

require 'spec_helper'

class OrderService < Zx::Result
  def initialize(tax: 0.1)
    @tax = tax
  end

  def apply(value)
    price = value + (value * @tax)

    return Failure! :priceless if price < 100

    Success! price: price
  end
end

RSpec.describe Zx do
  context 'order service use case' do
    it 'success' do
      order = OrderService.new(tax: 0.1)
      result = order.apply(100)

      expect(result).to be_success

      result
        .on(:success, :ok) { |r| expect(r[:price]).to eq(110) }
        .on(:failure, :error) { |_r| expect(r[:error]).to eq('is priceless') }
    end

    it 'failure price' do
      order = OrderService.new(tax: 0.1)
      result = order.apply(80)

      expect(result).to be_failure

      result
        .on(:success, :ok) { |r| expect(r[:price]).to eq(110) }
        .on(:failure, :error) { |r| expect(r).to eq(:priceless) }
    end
  end

  context 'using fmap' do
    it 'success' do
      order = OrderService.new(tax: 0.1)
      result = order.apply(100)

      result
        .fmap { |r| r[:price] + 1 }
        .on_success { expect(_1).to eq(111) }
        .on_failure { |error| expect(error).to eq(:priceless) }
    end
  end

  context 'using step' do
    it 'success' do
      order = OrderService.new(tax: 0.1)
      result = order.apply(100)

      result
        .step { |r| r[:price] + 1 }
        .step { |r| r + 2 }
        .on_success { expect(_1).to eq(113) }
        .on_failure { |error| expect(error).to eq(:priceless) }
    end
  end

  context 'using check' do
    it 'success' do
      order = OrderService.new(tax: 0.1)
      result = order.apply(100)

      result
        .step { |r| r[:price] + 1 }
        .check { |r| r == 111 }

      expect(result.type).to eq(:ok)
    end

    it 'failure' do
      order = OrderService.new(tax: 0.1)
      result = order.apply(100)

      result
        .step { |r| r[:price] + 1 }
        .check { |r| r == 112 }

      expect(result.type).to eq(:error)
    end
  end

  context 'as callable' do
    it 'using Success directly as method' do
      result = Zx.Success(1)
      expect(result.value).to eq(1)
    end

    it 'using Success directly as callable' do
      result = Zx::Success[1]
      expect(result.value).to eq(1)
    end

    it 'using Failure directly as method' do
      result = Zx.Failure('error')
      expect(result.value).to eq('error')
    end

    it 'using Failure directly as callable' do
      result = Zx::Failure['error']
      expect(result.value).to eq('error')
    end
  end
end
