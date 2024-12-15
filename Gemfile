source 'https://rubygems.org'

gemspec

ruby File.read('.ruby-version').strip

group :development, :test do
  gem 'bundler', '>= 1.14'
  gem 'rake'
  gem 'rubocop'
end

group :test do
  gem 'byebug'
  gem 'rspec'
  gem 'simplecov', require: false
end
