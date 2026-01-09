# frozen_string_literal: true

##
# Adds a further delivery method for imform admins when a
# user is blocked.
#
module RedmineLoginAttemptsLimit::Extensions::MailerPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.include(InstanceMethods)
      end

      ##
      # Injects ClassMethods into base class.
      #
      module ClassMethods
        def deliver_account_blocked(user)
          admin_users = User.active.where(admin: true).to_a
          admin_users.each do |admin_user|
            account_blocked(admin_user, user).deliver_later
          end
        end
      end

      ##
      # Injects InstanceMethods into base class.
      #
      module InstanceMethods
        ##
        # Informs admins only - avoid spam to other users
        #
        def account_blocked(admin, user)
          @user = user
          mail to: admin, subject: l('mailer.account_blocked_subject')
        end
      end
    end
end
