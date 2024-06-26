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
| unreleased     | main    | >= 2.5.8, <= 3.1.x |

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
  .check { |number| number == 15 }
  .on_failure{|error| puts error } #=> 10
```

### Try

```ruby
result = Zx.Try { 5 }
  .step{ |number| number + 5 }
  .check { |number| number == 15 }
  .on_failure{|error| puts error } #=> 10
```

### Given

```ruby
input = 5

result = Zx.Given(input)
  .then{ |number| number + 5 }
  .then{ |number| number + 5 }
  .then{ |number| number + 5 }
  .on_success{|number| number }
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

**Simple Inherit**

```ruby
class AsInherited
  include Zx

  def pass(...)
    Success(...)
  end

  def passthrough(value)
    Success[value]
  end

  def failed(error)
    Failure(error, type: :error)
  end
end

result = AsInherited.new.pass('save record!')

result
  .on(:success, :success) { expect(_1).to eq(a: 1) }
  .on(:success, :mailer) { expect(_1).to eq(a: 1) }
  .on(:success, :persisted) { expect(_1).to eq('save record!') }
  .on(:success) { |value, (type)| expect([value, type]).to eq(['save record!', :persisted]) }
  .on(:failure, :error) { expect(_1).to eq('on error') }
  .on(:failure, :record_not_found) { expect(_1).to eq('not found user') }
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

Zx::Failure[:invalid_user, 'user was not found']
```


[⬆️ &nbsp;Back to Top](#table-of-contents-)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thadeu/zx-result. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/thadeu/zx-result/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
