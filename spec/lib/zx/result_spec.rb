# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Zx::Result do
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
      result = Zx::Result.Failure('error', type: :invalid)

      expect(result.error).to eq('error')
      expect(result.type).to eq(:invalid)
    end

    it 'using on_failure listeners' do
      result = Zx::Result.Failure('invalid type tagged')

      expect(result.type).to eq(:error)

      result
        .on_success { expect(_1).to eq(a: 1) }
        .on_failure(:error) { expect(_1).to eq('invalid type tagged') }
        .on_failure(:invalid) { expect(_1).to eq('invalid') }
        .on_failure { expect(_1).to eq('invalid type tagged') }
    end

    it 'using on_failure listeners' do
      result = Zx::Result.Failure('as invalid', type: :invalid)

      expect(result.type).to eq(:invalid)

      result
        .on_success { expect(_1).to eq(a: 1) }
        .on_failure(:error) { expect(_1).to eq('invalid types tagged') }
        .on_failure(:invalid) { expect(_1).to eq('as invalid') }
    end

    it 'using on_unknown listeners' do
      result = Zx::Result.Failure('as invalid', type: :invalid)

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
      result = Zx::Result.Failure('not found user', type: :record_not_found)

      expect(result.type).to eq(:record_not_found)
      expect(result.value!).to eq('not found user')

      result
        .on(:success) { expect(_1).to eq(a: 1) }
        .on(:success, :send_mailer) { expect(_1).to eq(a: 1) }
        .on(:failure, :error) { expect(_1).to eq('not found') }
        .on(:failure, :record_not_found) { expect(_1).to eq('not found user') }
    end

    it 'using on_failure listeners' do
      result = Zx::Result.Failure('on error', type: 'mailer')

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
        result = Zx::Result.Success(a: 1)
        expect(result.value).to eq(a: 1)
      end

      it '#then' do
        result = Zx::Result.Success(a: 1)

        result.then { _1[:a] + 1 }

        expect(result.value).to eq(2)
      end

      it '#and_then' do
        result = Zx::Result.Success(a: 1)

        result.and_then { _1[:a] + 1 }

        expect(result.value).to eq(2)
      end

      it '#step' do
        result = Zx::Result.Success(a: 1)

        result.step { _1[:a] + 1 }

        expect(result.value).to eq(2)
      end

      it '#fmap' do
        result = Zx::Result.Success(a: 1)

        result.fmap { _1[:a] + 1 }

        expect(result.value).to eq(2)
      end

      context '#check' do
        it 'success' do
          result = Zx::Result.Success(a: 1)

          result
            .check { _1[:a] == 1 }
            .fmap { _1[:a] + 1 }

          expect(result.value).to eq(2)
        end

        it 'failure' do
          result = Zx::Result.Success(a: 1)

          result
            .check { _1[:a] == 2 }
            .then { _1[:a] + 1 }

          expect(result.value).to eq(nil)
        end
      end

      it 'using on_success listeners' do
        result = Zx::Result.Success a: 1

        expect(result.type).to eq(:ok)

        result.on_success { expect(_1).to eq(a: 1) }
      end

      it 'using on_success listeners' do
        result = Zx::Result.Success 1, type: :valid

        expect(result.type).to eq(:valid)

        result
          .on_success(:valid) { expect(_1).to eq(1) }
          .on_success(:user_found) { expect(_1).to eq(2) }
      end

      it 'using on_success listeners with custom arrow method' do
        result = Zx::Result.Success 1, type: :valid

        expect(result.type).to eq(:valid)

        result
          .>>(:success, :valid) { expect(_1).to eq(1) }
          .>>(:success, :user_found) { expect(_1).to eq(2) }

        result
          .|(:success, :valid) { expect(_1).to eq(1) }
          .|(:success, :user_found) { expect(_1).to eq(2) }

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
        result = Zx::Result.Success(a: 1)
        expect(result.value).to eq(a: 1)
      end

      it 'using directly as Hash' do
        result = Zx::Result::Success[a: 1]
        expect(result.value).to eq(a: 1)
      end

      it 'using directly as Hash' do
        result = Zx::Result::Failure['invalid']
        expect(result.value).to eq('invalid')
      end

      it 'using directly as Hash' do
        result = Zx::Result::Failure('invalid')
        expect(result.value).to eq('invalid')
      end
    end
  end
end
