# frozen_string_literal: true

module RedmineLoginAttemptsLimit::PluginSettings
  def setting
    Setting.plugin_redmine_login_attempts_limit
  end
end
