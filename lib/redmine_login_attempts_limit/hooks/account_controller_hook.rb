# frozen_string_literal: true

##
# Hook for AccountController successful authentication.
#
module RedmineLoginAttemptsLimit::Hooks
  class AccountControllerHook < ::Redmine::Hook::ViewListener
    def controller_account_success_authentication_after(context = {})
      user = context[:user]
      return unless user

      InvalidAccount.new(user.login).clear(user.login)
    end
  end
end
