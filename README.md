<p align="center">
  <h1 align="center">🔃 Zx::Result</h1>
  <p align="center"><i>Functional result object for Ruby</i></p>
</p>

<p align="center">
  <a href="https://rubygems.org/gems/zx-result">
    <img alt="Gem" src="https://img.shields.io/gem/v/zx-result.svg">    
  </a>

  <a href="https://github.com/thadeu/zx-result/actions/workflows/ci.yml">
    <img alt="Build Status" src="https://github.com/thadeu/zx-result/actions/workflows/ci.yml/badge.svg">
  </a>
</p>


## Motivation

Because in sometimes, we need to create a safe return for our objects. This gem simplify this work.

## Documentation <!-- omit in toc -->

Version    | Documentation
---------- | -------------
unreleased | https://github.com/thadeu/zx-result/blob/main/README.md

## Table of Contents <!-- omit in toc -->
  - [Installation](#installation)
  - [Usage](#usage)
    - [Success](#success)
    - [Failure](#failure)
    - [Try](#try)
    - [Given](#given)

## Compatibility

| kind           | branch  | ruby               |
| -------------- | ------- | ------------------ |
| unreleased     | main    | >= 2.5.8, <= 3 |

## Installation

Use bundle

```ruby
bundle add zx-result
```

or add this line to your application's Gemfile.

```ruby
gem 'zx-result'
```

and then, require module

```ruby
require 'zx'
```

## Configuration

Without configuration, because we use only Ruby. ❤️

## Usage

You can use with many towards.

### Given

```ruby
result = Zx.Given { Zx.Success(5) }
result.success? #=> true
result.failure? #=> false
result.value #=> 5
result.value! #=> 5 or raise
result.error #=> nil or raises an exception
```

```ruby
input = 5

result = Zx.Given(input)
  .then{ |number| number + 5 }
  .then{ |number| number + 5 }
  .then{ |number| number + 5 }
  .on_success{|number| number }
```

You can use `Given` to invoke other methods in the class, like this.

```ruby
class User
  def self.create(name:, email:)
    new(name:, email:).create
  end

  attr_reader :name, :email

  def initialize(name:, email:)
    @name = name
    @email = email
  end

  def create
    self
  end
end

class Account
  def self.create(user:)
    new(user:).create
  end

  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def create
    self
  end

  def send_welcome_email!
    true
  end
end

class NewsletterMailer
  def self.subscribe!(account:)
    new(account:).subscribe!
  end

  attr_reader :account

  def initialize(account:)
    @account = account
  end

  def subscribe!
    true
  end
end

class AccountCreation
  include Zx

  def self.deliver(input)
    new.deliver(input)
  end

  def deliver(input)
    Given(input)
      .and_then(&method(:create_user))
      .and_then(&method(:create_account))
      .and_then(&method(:subscribe_mailer))
      .and_then(&method(:send_welcome_email!))
  end

  def create_user(input)
    user = User.create(name: input[:name], email: input[:email])
    Success(user:, type: :user_created)
  end

  def create_account(user:, **)
    account = Account.create(user:)
    Success(account:, type: :account_created)
  end

  def subscribe_mailer(account:, **)
    NewsletterMailer.subscribe!(account:)
    Success(account:, type: :mailer_subscribed)
  end

  def send_welcome_email!(account:, **)
    account.send_welcome_email!
    Success(account, type: :email_sent)
  end
end

input = { name: 'Thadeu Esteves', email: 'tadeuu@gmail.com' }

account = AccountCreation.deliver(input)
  .on(:success, :user_created) { |user| p [:user_created, user] }
  .on(:success, :account_created) { |acc| p [:account_created, acc] }
  .on(:success, :mailer_subscribed) { |acc| p [:mailer_subscribed, acc] }
  .on(:success, :email_sent) { |acc| p [:email_sent, acc] }
  .on(:failure, :user_not_created) { |error| p [:user_not_created, error] }
  .otherwise { |error| p [:otherwise, error] }

expect(account.success?).to be_truthy
expect(account.type).to eq(:email_sent)
expect(account.unwrap.user.name).to eq('Thadeu Esteves')
expect(account.unwrap.user.email).to eq('tadeuu@gmail.com')
```

### Success

```ruby
result = Zx.Success(5)
result.success? #=> true
result.failure? #=> false
result.value #=> 5
result.value! #=> 5 or raise
result.error #=> nil or raises an exception
```

```ruby
result = Zx.Success(5, type: :integer)
result.success? #=> true
result.failure? #=> false
result.value #=> 5
result.value! #=> 5 or raise
result.error #=> nil or raises an exception
result.type #=> :integer
```

### Failure

```ruby
result = Zx.Failure(:fizz)
result.success? #=> false
result.failure? #=> true
result.value #=> raises an exception
result.error #=> :fizz
result.type #=> :error
```

```ruby
result = Zx.Failure(:fizz, type: :not_found)
result.success? #=> false
result.failure? #=> true
result.value #=> raises an exception
result.error #=> :fizz
result.type #=> :not_found
```

### Map or Then

```ruby
result = Zx.Success(5, type: :integer)
  .fmap{ |number| number + 5 }
  .fmap{ |number| number + 5 }
  .fmap{ |number| number + 5 }
  .on_success(:integer) {|number| puts number } #=> 20
  .on(:success, :integer) {|number| puts number } #=> 20
  .on_success {|number| puts number } #=> 20

result.success? #=> true
result.failure? #=> false
result.value #=> 20
result.value! #=> 20 or raise
result.error #=> nil or raises a  n exception
result.type #=> :integer
```

```ruby
result = Zx.Success(5, type: :integer)
  .then{ |number| number + 5 }
  .then{ |number| number + 5 }
  .then{ |number| number + 5 }
  .on_success{|number| puts number } #=> 20

result.success? #=> true
result.failure? #=> false
result.value #=> 20
result.value! #=> 20 or raise
result.error #=> nil or raises an exception
result.type #=> :integer
```

### Step or Check

```ruby
result = Zx.Success(5, type: :integer)
  .step{ |number| number + 5 }
  .on_success(:integer) {|number| puts number } #=> 10
  .on(:success, :integer) {|number| puts number } #=> 10
  .on_success {|number| puts number } #=> 10

result.success? #=> true
result.failure? #=> false
result.value #=> 10
result.value! #=> 10 or raise
result.error #=> nil or raises a  n exception
result.type #=> :integer
```

```ruby
result = Zx.Success(5, type: :integer)
  .step{ |number| number + 5 }
  .check { |number| number == 10 }
  .on_success{|number| puts number } #=> 10

result.success? #=> true
result.failure? #=> false
result.value #=> 10
result.value! #=> 10 or raise
result.error #=> nil or raises an exception
result.type #=> :integer
```

```ruby
result = Zx.Success(5, type: :integer)
  .step{ |number| number + 5 }
  .check(:number_valid) { |number| number == 15 }
  .on_failure { |error| puts error } #=> 10
```

### Try

```ruby
result = Zx.Try { Zx.Success(5) }
  .step { |number| number + 5 }
  .check(:number_invalid) { |number| number == 15 }
  .on_failure{ |error, (type)| puts [error, type] } # failure! because, number == 10, right?
  .on_success{ |number| puts number }
```

```ruby
result = Zx.Try { Zx.Success(10) }
  .step { |number| number + 1 }
  .then { |number| number + 1 }
  .and_then { |number| number + 1 }
  .fmap { |number| number + 1 }
  .check(:number_invalid) { |number| number == 15 }
  .on_failure{ |error, (type)| puts [:failure, error, type] }
  .on_success{ |number| puts [:success, number] }
```

```ruby
result = Zx.Try { Zx.Failure(10) }
  .step { |number| number + 1 }
  .then { |number| number + 1 }
  .and_then { |number| number + 1 }
  .fmap { |number| number + 1 }
  .check(:number_invalid) { |number| number == 15 }
  .on_failure{ |error, (type)| puts [:failure, error, type] }
  .on_success{ |number| puts [:success, number] }
```

You can use one or multiples listeners in your result. We see some use cases.

**Simple composition**

```ruby
class AsIncluded
  include Zx

  def pass(...)
    Success(...)
  end

  def passthrough(value)
    Success[value]
  end

  def failed(error)
    Failure[error, type: :error]
  end
end

result = AsIncluded.new.pass('save record!')

result
  .on(:success, :success) { expect(_1).to eq(a: 1) }
  .on(:success, :mailer) { expect(_1).to eq(a: 1) }
  .on(:success, :persisted) { expect(_1).to eq('save record!') }
  .on(:success) { |value, (type)| expect([value, type]).to eq(['save record!', :persisted]) }
  .on(:failure, :error) { expect(_1).to eq('on error') }
  .on(:failure, :record_not_found) { expect(_1).to eq('not found user') }
```

**Match**

```ruby
result = AsIncluded.new.pass('save record!')

result.match(
  Ok: ->(v) { [:ok, v] },
  Err: ->(err) { raise [:err, err] }
)

result.match(
  Ok: -> { expect(_1).to eq(2) },
  Err: -> { raise [:err, _1] }
)
```

**Otherwise**

```ruby
result = Zx.Failure('invalid type tagged')

result
  .on_success(:jump_this) { [:jump_this, _1] }
  .on_failure(:jump_this1) { [:jump_this1, _1] }
  .on_failure(:jump_this2) { [:jump_this2, _1] }
  .otherwise { p [:otherwise, _1] }
```

You can use directly methods, for example:

```ruby
Zx.Success(relation)

# or

Zx::Success[relation]
```

```ruby
Zx:.Failure('error', type: :invalid)

# or

Zx::Failure['user was not found', { type: :invalid_user }]
```


[⬆️ &nbsp;Back to Top](#table-of-contents-)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thadeu/zx-result. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/thadeu/zx-result/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
