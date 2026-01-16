# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = 'redmine_login_attempts_limit'
  spec.version = '0.0.0'
  spec.authors = ['midnightSuyama, RegioHelden, xmera-circle, Mattani']
  spec.summary = 'Redmine plugin to limit login attempts and block accounts after failed attempts'

  spec.required_ruby_version = '>= 2.7.0'

  # Runtime dependencies
  spec.add_dependency 'redis', '>= 4.0.1'
end
