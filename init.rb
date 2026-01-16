# frozen_string_literal: true

require File.expand_path('lib/redmine_login_attempts_limit', __dir__)

Redmine::Plugin.register :redmine_login_attempts_limit do
  name 'Login Attempts Limit'
  author 'midnightSuyama, Liane Hampe, xmera Solutions GmbH'
  description 'Login attempts limit plugin for Redmine'
  version '1.0.3'
  url 'https://github.com/xmera-circle/redmine_news_notification'

  requires_redmine_plugin :advanced_plugin_helper, version_or_higher: '0.4.0'

  settings default: {
    attempts_limit: 6,
    block_minutes: 60,
    blocked_notification: true
  }, partial: 'settings/redmine_login_attempts_limit_settings'
end

RedmineLoginAttemptsLimit.setup

# Initialize hook
RedmineLoginAttemptsLimit::Hooks::AccountControllerHook.instance
