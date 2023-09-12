# frozen_string_literal: true

require 'byebug'
require 'bundler/setup'
require 'zx'

Dir["#{File.expand_path(__dir__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
