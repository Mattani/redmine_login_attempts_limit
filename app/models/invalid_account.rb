# frozen_string_literal: true

##
# Store user related data of login attempts using Rails.cache so multiple
# processes can share lock information.
##
class InvalidAccount
  include ::RedmineLoginAttemptsLimit::PluginSettings

  class << self
  include ::RedmineLoginAttemptsLimit::PluginSettings

    # With cache-based storage entries expire automatically. Keep this
    # method for compatibility; it is a no-op unless the cache adapter
    # supports wildcard deletions.
    def clean_expired
      # Some cache stores support delete_matched; attempt cleanup if available.
      if Rails.cache.respond_to?(:delete_matched)
        Rails.cache.delete_matched(cache_key_prefix + '*')
      end
      nil
    end

    # Clear all cached invalid account entries. Best-effort: requires
    # cache adapter to implement wildcard deletion.
    def clear
      if Rails.cache.respond_to?(:delete_matched)
        Rails.cache.delete_matched(cache_key_prefix + '*')
      end
      nil
    end

    private

    def cache_key_prefix
      'redmine_login_attempts_limit:invalid_account:'
    end

    def minutes
      setting[:block_minutes].to_i
    end

    def now
      Time.zone.now
    end
  end

  def initialize(username = nil)
    self.username = username
  end

  def update
    return if user_key.blank?

    user_registered? ? update_cache_user_key : add_user_key_to_cache
  end

  def failed_count
    data = read_cache(user_key)
    data ? data[:failed_count].to_i : 0
  end

  def attempts_limit
    [limit, 1].max
  end

  def blocked?
    failed_count >= attempts_limit
  end

  ##
  # @params login [String] The login name of an identified user.
  #
  def clear(login = nil)
    return {} unless login

    Rails.cache.delete(cache_key_for(login.to_s.downcase))
    {}
  end

  private

  attr_accessor :username

  def now
    self.class.send(:now)
  end

  def user_key
    return unless username

    username.to_s.downcase
  end

  def cache_key_for(key)
    "#{self.class.send(:cache_key_prefix)}#{key}"
  end

  def read_cache(key)
    Rails.cache.read(cache_key_for(key))
  end

  def write_cache(key, value)
    # Use expires_in so entries are removed after configured block_minutes
  Rails.cache.write(cache_key_for(key), value, expires_in: minutes * 60)
  end

  def add_user_key_to_cache
    write_cache(user_key, { failed_count: 1, updated_at: now })
  end

  def update_cache_user_key
    key = read_cache(user_key) || { failed_count: 0, updated_at: now }
    key[:failed_count] = key[:failed_count].to_i + 1
    key[:updated_at] = now
    write_cache(user_key, key)
  end

  def limit
    setting[:attempts_limit].to_i
  end

  # Instance-level helper delegating to class-level settings
  def minutes
    self.class.send(:minutes)
  end

  def user_registered?
    @user_registered ||= !!read_cache(user_key)
  end
end
