# frozen_string_literal: true

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

  def self.create_with_method_blocks(input)
    new.create_with_method_blocks(input)
  end

  def self.create_with_method_symbols(input)
    new.create_with_method_symbols(input)
  end

  def create_with_method_blocks(input)
    Given(input)
      .and_then(&method(:create_user))
      .and_then(&method(:create_account))
      .and_then(&method(:subscribe_mailer))
      .and_then(&method(:send_welcome_email!))
  end

  def create_with_method_symbols(input)
    Given(input)
      .and_then(:create_user)
      .and_then(:create_account)
      .and_then(:subscribe_mailer)
      .and_then(:send_welcome_email!)
  end

  def create_user(input)
    user = User.create(name: input[:name], email: input[:email])
    Success({ user: }, type: :user_created)
  end

  def create_account(user:)
    account = Account.create(user:)
    Success({ account: }, type: :account_created)
  end

  def subscribe_mailer(account:)
    NewsletterMailer.subscribe!(account:)
    Success({ account: }, type: :mailer_subscribed)
  end

  def send_welcome_email!(account:)
    account.send_welcome_email!
    Success(account, type: :email_sent)
  end
end
