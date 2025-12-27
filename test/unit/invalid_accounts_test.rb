# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class InvalidAccountTest < ActiveSupport::TestCase
  def setup
    @plugin = Redmine::Plugin.find(:redmine_login_attempts_limit)
    Setting.define_plugin_setting(@plugin)
    @setting = Setting.plugin_redmine_login_attempts_limit
    @setting[:attempts_limit] = 3
    @setting[:block_minutes]  = 60
  end

  def teardown
  # Clear cache entries created by tests
  InvalidAccount.clear
  @setting = nil
  @plugin = nil
  Setting.plugin_redmine_login_attempts_limit = {}
  end

  def test_update
    admin = invalid_user_admin
  admin.update
  # cached structure should contain failed_count and updated_at
  cached = Rails.cache.read(cache_key('admin'))
  assert_equal 1, admin.failed_count
  assert_equal 1, cached[:failed_count]
  assert_kind_of Time, cached[:updated_at]

  admin.update
  assert_equal 2, admin.failed_count
  end

  def test_failed_count
    admin = invalid_user_admin
    admin.update
    assert_equal 1, admin.failed_count
    assert_equal 0, invalid_user_bob.failed_count
  end

  def test_attempts_limit
    @setting[:attempts_limit] = 10
    assert_equal 10, invalid_account.attempts_limit

    @setting[:attempts_limit] = 0
    assert_equal 1, invalid_account.attempts_limit
  end

  def test_blocked?
    bob = invalid_user_bob
    3.times { bob.update }
    assert bob.blocked?

    admin = invalid_user_admin
    2.times { admin.update }
    assert_not admin.blocked?
  end

  def test_clear
    bob = invalid_user_bob
    bob.update
    fred = invalid_user_fred
    fred.update
    barney_m = invalid_user_barney_m
    barney_m.update

    # clear single user
    fred.clear('Fred')
    assert_nil Rails.cache.read(cache_key('fred'))

    # remaining users still present
    assert_equal 2, [Rails.cache.read(cache_key('admin')), Rails.cache.read(cache_key('barneym'))].compact.length

    bob.clear('Bob')
    barney_m.clear('BarneyM')
    assert_nil Rails.cache.read(cache_key('admin'))
    assert_nil Rails.cache.read(cache_key('barneym'))
  end

  def test_clean_expired
    bob = invalid_user_bob
    bob.update
    fred = invalid_user_fred
    fred.update
    barney_m = invalid_user_barney_m
    barney_m.update

    # Simulate expiry by setting fred.updated_at in the past
    key = cache_key('fred')
    data = Rails.cache.read(key)
    if data
      data[:updated_at] = data[:updated_at] - ((60 * 60) + 1)
      Rails.cache.write(key, data)
    end

    # clean_expired is best-effort depending on cache adapter support
    InvalidAccount.clean_expired
    if Rails.cache.respond_to?(:delete_matched)
      assert_nil Rails.cache.read(key)
    else
      # no-op for adapters that don't support wildcard deletion; ensure no error
      assert true
    end
  end

  private

  def invalid_user_admin
    invalid_account('admin')
  end

  def invalid_user_bob
    invalid_account('Bob') # user1
  end

  def invalid_user_fred
    invalid_account('Fred') # user2
  end

  def invalid_user_barney_m
    invalid_account('BarneyM') # user3
  end

  def invalid_account(username = nil)
    InvalidAccount.new(username)
  end

  def cache_key(username)
    "redmine_login_attempts_limit:invalid_account:#{username.to_s.downcase}"
  end
end
