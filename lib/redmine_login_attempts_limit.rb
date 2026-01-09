# frozen_string_literal: true

##
# Initialize the plugins setup.
#
module RedmineLoginAttemptsLimit
  class << self
    def setup
      klasses.each do |klass|
        patch = send("#{klass}_patch")
        AdvancedPluginHelper::Patch.register(patch)
      end
    end

    private

    def klasses
      %w[account mailer]
    end

    def account_patch
      { klass: AccountController,
        patch: RedmineLoginAttemptsLimit::Overrides::AccountControllerPatch,
        strategy: :prepend }
    end

    def mailer_patch
      { klass: Mailer,
        patch: RedmineLoginAttemptsLimit::Extensions::MailerPatch,
        strategy: :include }
    end
  end
end

# Extensions
require_relative 'redmine_login_attempts_limit/extensions/mailer_patch'

# Overrides
require_relative 'redmine_login_attempts_limit/overrides/account_controller_patch'

# Others
require_relative 'redmine_login_attempts_limit/plugin_settings'
