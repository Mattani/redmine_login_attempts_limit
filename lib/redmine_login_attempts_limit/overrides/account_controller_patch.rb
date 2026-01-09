# frozen_string_literal: true

##
# Overrides methods of AccountController.
#
module RedmineLoginAttemptsLimit::Overrides::AccountControllerPatch
  def self.prepended(base)
    base.send(:prepend, InstanceMethods)
  end

  ##
  # Instance methods to be prepended.
  #
  module InstanceMethods
    include RedmineLoginAttemptsLimit::PluginSettings

    # @override AccountController#password_authentication
    def password_authentication
      return super unless invalid_account.blocked?

      # Log blocked authentication attempt with user id and remote IP
      begin
        uid = user&.id
        Rails.logger.info "[redmine_login_attempts_limit] blocked authentication attempt user_id=#{uid.inspect} username=#{username.inspect} ip=#{request.remote_ip rescue 'unknown'}"
      rescue StandardError => e
        Rails.logger.error "[redmine_login_attempts_limit] failed to log blocked attempt: #{e.message}"
      end

      flash.now[:error] = l('errors.blocked')
    end

    # @override AccountController#invalid_credentials
    def invalid_credentials
      # Skip increment if already blocked
      was_blocked = invalid_account.blocked?
      invalid_account.update unless was_blocked

      super
      return unless invalid_account.blocked?

      # Log locked user id when the account becomes blocked
      begin
        if !was_blocked && user.present?
          Rails.logger.info "[redmine_login_attempts_limit] account locked for user_id=#{user.id}"
        end
      rescue StandardError => e
        Rails.logger.error "[redmine_login_attempts_limit] failed to log locked user id: #{e.message}"
      end

      flash.now[:error] = l('errors.blocked')
      Mailer.deliver_account_blocked(user) if notification? && user.present?
    end

    def successful_authentication(user)
      invalid_account.clear(user.login)
      super
    end

    def user
      @user = User.find_by(login: username)
    end

    def invalid_account
      @invalid_account ||= InvalidAccount.new(username)
    end

    def username
      params[:username]
    end

    def token
      Token.find_token('recovery', params[:token].to_s)
    end

    def notification?
      setting['blocked_notification']
    end
  end
end
