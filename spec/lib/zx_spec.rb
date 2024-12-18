# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Zx do
  describe 'Try' do
    context 'with block' do
      it 'success' do
        result = Zx.Try { 1 }

        expect(result.value).to eq(1)
        expect(result.success?).to be_truthy
        expect(result.type).to eq(:ok)
      end

      it 'failure' do
        result = Zx.Try { Failure(1) }

        expect(result.value).to be_nil
        expect(result.success?).to be_falsey
        expect(result.type).to eq(:error)
      end

      it 'raise with failure' do
        result = Zx.Try { raise Failure(1) }

        expect(result.value).to be_nil
        expect(result.success?).to be_falsey
        expect(result.type).to eq(:error)
      end

      it 'raise with failure and fallback' do
        result = Zx.Try(nil, or: 1) { raise Failure(1) }

        expect(result.value).to eq(1)
        expect(result.success?).to be_falsey
        expect(result.type).to eq(:error)
      end
    end

    context 'without block' do
      it 'success' do
        result = Zx.Try(1)

        expect(result.value).to eq(1)
        expect(result.success?).to be_truthy
        expect(result.type).to eq(:ok)
      end
    end
  end

  describe 'Given' do
    context 'with block' do
      it 'success' do
        result = Zx.Given { Zx.Success(Zx.Success(Zx.Success(1))) }

        result
          .on(:success, :ok) { expect(_1).to eq(1) }
          .on(:failure, :error) { expect(_1).not_to be_nil }

        expect(result.unwrap).to eq(1)
        expect(result.success?).to be_truthy
        expect(result.type).to eq(:ok)
      end

      it 'failure' do
        result = Zx.Given { Failure(1) }

        expect(result.value).to be_nil
        expect(result.success?).to be_falsey
        expect(result.type).to eq(:error)
      end

      it 'raise with failure' do
        result = Zx.Given { raise Failure(1) }

        expect(result.value).to be_nil
        expect(result.success?).to be_falsey
        expect(result.type).to eq(:error)
      end

      it 'raise with failure and fallback' do
        result = Zx.Given(nil, or: 1) { raise Failure(1) }

        expect(result.value).to eq(1)
        expect(result.success?).to be_falsey
        expect(result.type).to eq(:error)
      end
    end

    context 'without block' do
      it 'success' do
        result = Zx.Given(1)

        expect(result.value).to eq(1)
        expect(result.success?).to be_truthy
        expect(result.type).to eq(:ok)
      end
    end
  end

  context 'using nested and_then' do
    it 'keep the last result type in the tree' do
      ok1 = Zx.Success(1)
      fail1 = Zx.Failure(ok1, type: :catched)

      ok2 = Zx.Success(2)
      fail2 = Zx.Failure(ok2, type: :failed)

      expect([fail1.unwrap, fail2.unwrap]).to eq([1, 2])

      # The Zx.Success was the last result that we found it
      # Even if the first result was a Zx.Failure
      expect([fail1.type, fail2.type]).to eq(%i(ok ok))
    end

    context 'when a success exists in the chain' do
      it 'returns unwrapped value' do
        result = NestedAndThen.new.call_ok_hash(0)

        expect(result.value!).to eq(2)
      end

      it 'returns the Zx::Result instance' do
        result = NestedAndThen.new.call_ok_kw

        expect(result).to be_a(Zx::Result)
        expect(result.value).to eq(2)
        expect(result.type).to eq(:continue)

        result
          .on(:failure, :math) { raise [:failure, _1] }
          .on(:success, :jump1) { raise [:jump1, _1] }
          .on(:success, :continue) { |r| expect(r).to eq(2) }
      end

      it 'returns the Zx::Result otherwise' do
        result = NestedAndThen.new.call_ok_kw

        expect(result).to be_a(Zx::Result)

        result
          .on_failure(:jump1) { raise [:jump1, _1] }
          .on_failure(:jump2) { raise [:jump2, _1] }
          .on_success(:jump3) { raise [:jump3, _1] }
          .otherwise { expect(_1).to eq(2) }
      end

      context '.match' do
        it 'block without argument like JS' do
          result = NestedAndThen.new.call_ok_kw

          expect(result).to be_a(Zx::Result)

          OkBlock = lambda do |v, type|
            expect(v).to eq(2)
            { success: true, value: v }
          end

          matches = {
            Ok: OkBlock,
            Err: ->(err) { raise [:err, err] }
          }

          matched = result.match(**matches)

          expect(matched[:success]).to be_truthy
          expect(matched[:value]).to eq(2)
        end

        it 'block without argument like JS' do
          result = NestedAndThen.new.call_ok_kw

          expect(result).to be_a(Zx::Result)

          result.match(
            Ok: ->(v) { expect(v).to eq(2) },
            Err: ->(err) { raise [:err, err] }
          )
        end

        it 'block Err with method argument' do
          result = NestedAndThen.new.call_ok_kw

          expect(result).to be_a(Zx::Result)

          result.match(
            Ok: -> { expect(_1).to eq(2) },
            Err: -> { raise [:err, _1] }
          )
        end

        it 'block with method argument' do
          result = NestedAndThen.new.call_failure_no_unwrap

          expect(result).to be_a(Zx::Result)

          def expected_error(err, type = nil)
            expect(type).to eq(:error1)
            expect(err).not_to be_nil
            expect(err).to eq('error 1')
          end

          result.match(
            Ok: -> { raise [:ok, _1] },
            Err: ->(err, type) { expected_error(err, type) }
          )
        end
      end
    end

    context 'when a failure exists in the chain' do
      it 'stop flow and then return the failure step' do
        result = NestedAndThen.new.call_failure1

        expect(result).to eq('error 1')
      end

      it 'stop flow and then return the failure step' do
        result = NestedAndThen.new.call_failure2

        expect(result).to eq('error 2')
      end
    end
  end

  context 'order service use case' do
    it 'nested failure and success' do
      order = OrderService.new(tax: 0.1)
      result = order.apply_nested(100)

      result
        .and_then { |price| Zx.Success(price) }

      expect(result.type).to eq(:priceless_1)
      expect(result.value).to eq(0)
      expect(result.success?).to be_falsey
    end

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
      result2 = order.apply(100)
      result3 = order.apply(100)

      result
        .fmap { |r| r[:price] + 1 }
        .on_success { expect(_1).to eq(111) }
        .on_failure { |error| expect(error).not_to eq(:priceless) }

      result2
        .fmap { |r| Zx.Success(r[:price] + 1) }
        .on_success { expect(_1).to eq(111) }
        .on_failure { |error| expect(error).not_to eq(:priceless) }

      # result3
      #   .fmap { |r| Zx.Failure(Zx.Success(r[:price] + 1)) }
      #   .on_success { expect(_1).not_to eq(111) }
      #   .on_failure { |error| expect(error).to eq(111) }
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

  describe 'inherited' do
    it 'success using as base' do
      result = AsInherited.new.pass(a: 1)

      expect(result.type).to eq(:ok)
      expect(result.value).to eq(a: 1)
    end

    it 'success using as base' do
      result = AsInherited.new.passthrough(a: 1)

      expect(result.type).to eq(:ok)
      expect(result.value).to eq(a: 1)
    end

    it 'fail using as base' do
      result = AsInherited.new.failed(message: 'was error')

      expect(result.type).to eq(:error)
      expect(result.value[:message]).to eq('was error')
    end

    it 'methods doesnt exists in the public_instance_methods' do
      result = AsInherited.new

      expect(result.public_methods).to include(:Success)
      expect(result.public_methods).to include(:Failure)
    end
  end

  describe 'extended' do
    it 'success using as base' do
      result = AsExtended.pass(a: 1)

      expect(result.type).to eq(:ok)
      expect(result.value).to eq(a: 1)
    end

    it 'success using as base' do
      result = AsExtended.passthrough(a: 1)

      expect(result.type).to eq(:ok)
      expect(result.value).to eq(a: 1)
    end

    it 'fail using as base' do
      result = AsExtended.failed(message: 'was error')

      expect(result.type).to eq(:error)
      expect(result.value[:message]).to eq('was error')
    end
  end

  describe 'composition' do
    it 'using as private mixin' do
      result = AsComposition.new.pass(a: 1)
      expect(result.value).to eq(a: 1)
    end

    it 'using as concern directly' do
      result = AsComposition.new.failed('error')
      expect(result.error).to eq('error')
    end

    it 'using on_success listeners' do
      result = AsComposition.new.pass('save record!', type: :persisted)

      expect(result.type).to eq(:persisted)
      expect(result.value!).to eq('save record!')

      result
        .on(:success, :success) { expect(_1).to eq(a: 1) }
        .on(:success, :mailer) { expect(_1).to eq(a: 1) }
        .on(:success, :persisted) { expect(_1).to eq('save record!') }
        .on(:success) { |value, (type)| expect([value, type]).to eq(['save record!', :persisted]) }
        .on(:failure, :error) { expect(_1).to eq('on error') }
        .on(:failure, :record_not_found) { expect(_1).to eq('not found user') }
    end

    it 'using on_failure listeners' do
      result = AsComposition.new.failed('error')

      expect(result.type).to eq(:error)
      expect(result.value!).to eq('error')

      result
        .on(:success, :success) { expect(_1).to eq(a: 1) }
        .on(:success, :mailer) { expect(_1).to eq(a: 1) }
        .on(:success, :persisted) { expect(_1).to eq('save record!') }
        .on(:success) { |value, (type)| expect([value, type]).to eq(['save record!', :persisted]) }
        .on(:failure, :record_not_found) { expect(_1).to eq('not found users') }
        .on(:failure, :error) { expect(_1).to eq('error') }
        .on(:failure) { expect(_1).to eq('error') }
        .on_failure(:error) { expect(_1).to eq('error') }
        .on_failure { expect(_1).to eq('error') }
    end
  end

  describe '#failure' do
    it 'using fail directly' do
      result = Zx.Failure('error', type: :invalid)

      expect(result.error).to eq('error')
      expect(result.type).to eq(:invalid)
    end

    it 'using on_failure listeners' do
      result = Zx.Failure('invalid type tagged')

      expect(result.type).to eq(:error)

      result
        .on_success { expect(_1).not_to eq(a: 1) }
        .on_failure(:jump1) { expect(_1).not_to eq('invalid type tagged') }
        .on_failure(:jump2) { expect(_1).not_to eq('invalid') }
        .otherwise { expect(_1).to eq('invalid type tagged') }
    end

    it 'using on_failure listeners' do
      result = Zx.Failure('as invalid', type: :invalid)

      expect(result.type).to eq(:invalid)

      result
        .on_success { expect(_1).to eq(a: 1) }
        .on_failure(:error) { expect(_1).to eq('invalid types tagged') }
        .on_failure(:invalid) { expect(_1).to eq('as invalid') }
    end

    it 'using on_unknown listeners' do
      result = Zx.Failure('as invalid', type: :invalid)

      expect(result.type).to eq(:invalid)

      result
        .on_success { expect(_1).to eq(a: 1) }
        .on_failure(:rescue) { expect(_1).to eq('invalid types tagged') }
        .on_failure(:not_found) { expect(_1).to eq('as invalid') }
        .on_unknown do |value, (type, success)|
          expect(value).to eq('as invalid')
          expect(type).to eq(:invalid)
          expect(success).to be_falsey
        end
    end

    it 'using on_failure listeners' do
      result = Zx.Failure('not found user', type: :record_not_found)

      expect(result.type).to eq(:record_not_found)
      expect(result.value!).to eq('not found user')

      result
        .on(:success) { expect(_1).to eq(a: 1) }
        .on(:success, :send_mailer) { expect(_1).to eq(a: 1) }
        .on(:failure, :error) { expect(_1).to eq('not found') }
        .on(:failure, :record_not_found) { expect(_1).to eq('not found user') }
    end

    it 'using on_failure listeners' do
      result = Zx.Failure('on error', type: 'mailer')

      expect(result.type).to eq(:mailer)
      expect(result.value!).to eq('on error')

      result
        .on(:success) { expect(_1).to eq(a: 1) }
        .on(:success, :mailer) { expect(_1).to eq(a: 1) }
        .on(:failure, :error) { expect(_1).to eq('on errors') }
        .on(:failure, :mailer) { |error, (type)| expect([error, type]).to eq(['on error', :mailer]) }
        .on(:failure, :record_not_found) { expect(_1).to eq('not found user') }
    end
  end

  describe '#success' do
    context 'as method' do
      it 'using directly' do
        result = Zx.Success(a: 1)
        expect(result.value).to eq(a: 1)
      end

      it '#then' do
        result = Zx.Success(a: 1)

        result.then { _1[:a] + 1 }

        expect(result.value).to eq(2)
      end

      it '#and_then' do
        result = Zx.Success(a: 1)

        result.and_then { _1[:a] + 1 }

        expect(result.value).to eq(2)
      end

      it '#step' do
        result = Zx.Success(a: 1)

        result.step { _1[:a] + 1 }

        expect(result.value).to eq(2)
      end

      it '#fmap' do
        result = Zx.Success(a: 1)

        result.fmap { _1[:a] + 1 }

        expect(result.value).to eq(2)
      end

      context '#check' do
        it 'success' do
          result = Zx.Success(a: 1)

          result
            .check { _1[:a] == 1 }
            .fmap { _1[:a] + 1 }

          expect(result.value).to eq(2)
        end

        it 'failure' do
          result = Zx.Success(a: 1)

          result
            .check { _1[:a] == 2 }
            .then { _1[:a] + 1 }

          expect(result.value).to eq(nil)
        end
      end

      it 'using on_success listeners' do
        result = Zx.Success a: 1

        expect(result.type).to eq(:ok)

        result.on_success { expect(_1).to eq(a: 1) }
      end

      it 'using on_success listeners' do
        result = Zx.Success 1, type: :valid

        expect(result.type).to eq(:valid)

        result
          .on_success(:valid) { expect(_1).to eq(1) }
          .on_success(:user_found) { expect(_1).to eq(2) }
      end

      it 'using on_success listeners with custom arrow method' do
        result = Zx.Success 1, type: :valid

        expect(result.type).to eq(:valid)

        result
          .on(:success, :valid) { expect(_1).to eq(1) }
          .on(:success, :user_found) { expect(_1).to eq(2) }

        result
          .pipe(:success, :valid) { expect(_1).to eq(1) }
          .pipe(:success, :user_found) { expect(_1).to eq(2) }
      end
    end

    context 'as callable' do
      it 'using directly as Hash' do
        result = Zx.Success(1)
        expect(result.value).to eq(1)
      end

      it 'using directly as Hash' do
        result = Zx.Failure('error')
        expect(result.value).to eq('error')
      end

      it 'using directly as Hash' do
        result = Zx::Failure['error']
        expect(result.value).to eq('error')
      end

      it 'using directly as Hash' do
        result = Zx::Success[1]
        expect(result.value).to eq(1)
      end

      it 'using directly as Hash' do
        result = Zx.Success(a: 1)
        expect(result.value).to eq(a: 1)
      end

      it 'using directly as Hash' do
        result = Zx::Success[a: 1]
        expect(result.value).to eq(a: 1)
      end

      it 'using directly as Hash' do
        result = Zx::Failure['invalid']
        expect(result.value).to eq('invalid')
      end

      it 'using directly as Hash' do
        result = Zx::Failure('invalid')
        expect(result.value).to eq('invalid')
      end
    end
  end

  it 'raised FailureError' do
    result = Zx.Success(1)

    result.check { |v| v == 0 }

    expect { result.value! }.to raise_error(Zx::Result::FailureError)
  end

  describe 'process using method blocks' do
    it 'returns a Given result' do
      input = { name: 'Thadeu Esteves', email: 'tadeuu@gmail.com' }

      account = AccountCreation.create_with_method_blocks(input)
        .on(:success, :user_created) { |user| p [:user_created, user] }
        .on(:success, :account_created) { |acc| p [:account_created, acc] }
        .on(:success, :mailer_subscribed) { |acc| p [:mailer_subscribed, acc] }
        .on(:success, :email_sent) { |acc| expect(acc.user.name).to eq('Thadeu Esteves') }
        .on(:failure, :user_not_created) { |error| p [:user_not_created, error] }
        .otherwise { |error| p [:otherwise, error] }

      expect(account.success?).to be_truthy
      expect(account.type).to eq(:email_sent)
      expect(account.unwrap.user.name).to eq('Thadeu Esteves')
      expect(account.unwrap.user.email).to eq('tadeuu@gmail.com')
    end
  end

  describe 'process methods symbols' do
    it 'returns a Given result' do
      input = { name: 'Thadeu Esteves', email: 'tadeuu@gmail.com' }

      account = AccountCreation.create_with_method_symbols(input)
        .on(:success, :user_created) { |user| p [:user_created, user] }
        .on(:success, :account_created) { |acc| p [:account_created, acc] }
        .on(:success, :mailer_subscribed) { |acc| p [:mailer_subscribed, acc] }
        .on(:success, :email_sent) { |acc| expect(acc.user.name).to eq('Thadeu Esteves') }
        .on(:failure, :user_not_created) { |error| p [:user_not_created, error] }
        .otherwise { |error| p [:otherwise, error] }

      expect(account.success?).to be_truthy
      expect(account.type).to eq(:email_sent)
      expect(account.unwrap.user.name).to eq('Thadeu Esteves')
      expect(account.unwrap.user.email).to eq('tadeuu@gmail.com')
    end
  end
end
