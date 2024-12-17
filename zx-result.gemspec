# frozen_string_literal: true

require_relative 'lib/zx/version'

Gem::Specification.new do |spec|
  spec.name          = 'zx-result'
  spec.version       = Zx::VERSION
  spec.authors       = ['Thadeu Esteves']
  spec.email         = ['tadeuu@gmail.com']
  spec.summary       = 'Functional result object for Ruby'
  spec.description   = 'Expose an methods to create result object flow'
  spec.homepage      = 'https://github.com/thadeu/zx-result'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.required_ruby_version = '>= 2.7.6'
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'false'
end
