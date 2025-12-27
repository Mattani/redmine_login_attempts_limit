#!/usr/bin/env bash
# Run two concurrent processes of the multi_process_cache_test.rb script to observe shared cache behavior.
# Pre-requisites:
#  - Redis server running (if using Redis)
#  - Rails environment set to test
#  - Run the script in the Redmine root directory
# Usage:
#  Executing using MemoryStore:
#    RAILS_ENV=test ./plugins/redmine_login_attempts_limit/scripts/run-multi-process-cache-test.bash
#    or
#    TEST_CACHE=memory RAILS_ENV=test ./plugins/redmine_login_attempts_limit/scripts/run-multi-process-cache-test.bash
#  Result to be FAIL because the MemoryStore does not share cache between processes.
#
#  Executing using Redis:
#    TEST_CACHE=redis REDIS_URL=redis://localhost:6379/1 RAILS_ENV=test ./plugins/redmine_login_attempts_limit/scripts/run-multi-process-cache-test.bash
#  Result to be PASS because the Redis store shares cache between processes.

set -e
KEY=${1:-multi-test}
ITERATIONS=${2:-50}
DELAY=${3:-0.1}

echo "Starting two concurrent runners: key=${KEY} iterations=${ITERATIONS} delay=${DELAY}"

# Number of concurrent processes started by this script
PROCESSES=2
EXPECTED=$((ITERATIONS * PROCESSES))

echo "Expected final value (if cache is shared): ${EXPECTED}"

# Initialize the cache key to 0 so repeated script runs don't accumulate
TEST_CACHE=${TEST_CACHE:-} REDIS_URL=${REDIS_URL:-} MPC_KEY=${KEY} RAILS_ENV=test bundle exec rails runner "
	begin
		if ENV['TEST_CACHE'] == 'redis'
			redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/1'
			Rails.cache = ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)
		else
			Rails.cache = ActiveSupport::Cache::MemoryStore.new
		end
	rescue StandardError
		# ignore cache init errors
	end
		# write as raw so Redis stores a plain integer string
		Rails.cache.write(ENV['MPC_KEY'], 0, raw: true)
"

# Start first in background
TEST_CACHE=${TEST_CACHE:-} REDIS_URL=${REDIS_URL:-} RAILS_ENV=test bundle exec rails runner "
	# configure cache for runner according to TEST_CACHE
	begin
		if ENV['TEST_CACHE'] == 'redis'
			redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/1'
			Rails.cache = ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)
		else
			Rails.cache = ActiveSupport::Cache::MemoryStore.new
		end
	rescue StandardError
		# ignore if ActiveSupport cache classes are unavailable
	end
	script = Rails.root.join('plugins','redmine_login_attempts_limit','scripts','multi_process_cache_test.rb').to_s
	require script
	MultiProcessCacheTest.run('${KEY}','${ITERATIONS}','${DELAY}')
" &
PID1=$!

# Small stagger
sleep 0.2

# Start second in foreground
TEST_CACHE=${TEST_CACHE:-} REDIS_URL=${REDIS_URL:-} RAILS_ENV=test bundle exec rails runner "
	# configure cache for runner according to TEST_CACHE
	begin
		if ENV['TEST_CACHE'] == 'redis'
			redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/1'
			Rails.cache = ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)
		else
			Rails.cache = ActiveSupport::Cache::MemoryStore.new
		end
	rescue StandardError
		# ignore if ActiveSupport cache classes are unavailable
	end
	script = Rails.root.join('plugins','redmine_login_attempts_limit','scripts','multi_process_cache_test.rb').to_s
	require script
	MultiProcessCacheTest.run('${KEY}','${ITERATIONS}','${DELAY}')
"

wait $PID1

echo "Both processes finished."

# Read actual cache value using same cache settings
ACTUAL=$(TEST_CACHE=${TEST_CACHE:-} REDIS_URL=${REDIS_URL:-} MPC_KEY=${KEY} RAILS_ENV=test bundle exec rails runner "
	begin
		if ENV['TEST_CACHE'] == 'redis'
			redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/1'
			Rails.cache = ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)
		else
			Rails.cache = ActiveSupport::Cache::MemoryStore.new
		end
	rescue StandardError
		# ignore cache init errors
	end
	puts (Rails.cache.read(ENV['MPC_KEY'], raw: true).to_i rescue 0)
")

echo "Actual final cache value for key='${KEY}': ${ACTUAL}"

if [ "${ACTUAL}" -eq "${EXPECTED}" ] 2>/dev/null; then
	echo "VERDICT: PASS (shared cache behavior)"
else
	echo "VERDICT: FAIL (not shared or unexpected value)"
fi
