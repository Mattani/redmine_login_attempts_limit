# frozen_string_literal: true

require File.expand_path('../../../test/test_helper', __dir__)
require_relative 'authenticate_user'

# Ensure tests use a deterministic cache. Use TEST_CACHE=redis to test
# multi-process shared cache behavior with Redis (set REDIS_URL accordingly).
begin
	if defined?(Rails) && Rails.respond_to?(:cache)
		if ENV['TEST_CACHE'] == 'redis'
			redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/1'
			Rails.cache = ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)
		else
			Rails.cache = ActiveSupport::Cache::MemoryStore.new
		end
	end
rescue StandardError
	# ignore if cache cannot be set here
end
