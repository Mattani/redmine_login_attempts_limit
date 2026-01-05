# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = 'redmine_login_attempts_limit'
  spec.version = '0.0.0'

  # Runtime dependencies
  spec.add_runtime_dependency 'redis', '>= 4.0.1'
end
