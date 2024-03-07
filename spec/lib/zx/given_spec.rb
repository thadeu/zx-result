# frozen_string_literal: true

require 'spec_helper'

Downcase = ->(str) { str.downcase }

RSpec.describe Given do
  describe '#and_then' do
    it 'dont morphing input' do
      attributes = { first_name: 'THADEU', last_name: 'JUNIOR' }

      result = Given(attributes)
        .and_then { |attrs| attrs[:first_name] = Downcase[attrs[:first_name]] }
        .and_then { |attrs| attrs[:last_name] = Downcase[attrs[:last_name]] }
        .unwrap

      expect(result[:first_name]).to eq('thadeu')
      expect(result[:last_name]).to eq('junior')
    end

    it 'morphing input' do
      attributes = { first_name: 'THADEU', last_name: 'JUNIOR' }

      result = Given(attributes)
        .and_then { |attrs| attrs[:first_name] = Downcase[attrs[:first_name]] }
        .and_then { |attrs| attrs[:last_name] = Downcase[attrs[:last_name]] }
        .and_then! { |attrs| attrs.slice(:first_name) }
        .unwrap

      expect(result[:first_name]).to eq('thadeu')
      expect(result[:last_name]).not_to eq('junior')
    end

    it 'using inside class' do
      mailer = UserMailer.new
      result = mailer.deliver(first_name: 'thadeu')

      expect(result).to be_success
      expect(result.unwrap).to eq(first_name: 'thadeu')
    end

    it 'using inside class raised' do
      mailer = UserMailer.new

      result = mailer
        .deliver(first_name: 'thadeu')
        .and_then { raise StandardError, 'be error' }

      expect(result).to be_failure
      expect(result.unwrap).to eq('be error')
    end
  end
end
