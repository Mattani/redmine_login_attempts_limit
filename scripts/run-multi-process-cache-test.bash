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

# Helper: run a ruby snippet under the Rails runner with the same TEST_CACHE/REDIS_URL env
run_ruby() {
	local ruby_code="$1"
	# Pipe the ruby_code to rails runner via stdin (use '-' to force reading from stdin)
	# Ensure MPC_KEY is provided to the runner (use existing MPC_KEY env or fall back to script KEY)
	local mpc_env="${MPC_KEY:-${KEY}}"
	TEST_CACHE=${TEST_CACHE:-} REDIS_URL=${REDIS_URL:-} MPC_KEY=${mpc_env} RAILS_ENV=test printf "%s" "$ruby_code" | bundle exec rails runner -
}

# Common Ruby snippet to initialize Rails.cache according to TEST_CACHE/REDIS_URL
# stored as a heredoc to preserve quoting and newlines.
RUBY_CACHE_INIT=$(cat <<'RUBYCODE'
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
RUBYCODE
)

# Helper: common cache initialization used by workers and final reader
# Initialize the cache key to 0 so repeated script runs don't accumulate
init_cache_key() {
	run_ruby "${RUBY_CACHE_INIT}
key = ENV['MPC_KEY'] || '${KEY}'
Rails.cache.write(key, 0, raw: true)"
}

init_cache_key

# Start first in background
run_ruby "${RUBY_CACHE_INIT}
script = Rails.root.join('plugins','redmine_login_attempts_limit','scripts','multi_process_cache_test.rb').to_s
require script
MultiProcessCacheTest.run('${KEY}','${ITERATIONS}','${DELAY}')" &
PID1=$!

# Small stagger
sleep 0.2

# Start second in foreground
run_ruby "${RUBY_CACHE_INIT}
script = Rails.root.join('plugins','redmine_login_attempts_limit','scripts','multi_process_cache_test.rb').to_s
require script
MultiProcessCacheTest.run('${KEY}','${ITERATIONS}','${DELAY}')"

wait $PID1

echo "Both processes finished."

# Read actual cache value using same cache settings
ACTUAL=$(TEST_CACHE=${TEST_CACHE:-} REDIS_URL=${REDIS_URL:-} MPC_KEY=${KEY} RAILS_ENV=test run_ruby "${RUBY_CACHE_INIT}
key = ENV['MPC_KEY'] || '${KEY}'
puts (Rails.cache.read(key, raw: true).to_i rescue 0)")
echo "Actual final cache value for key='${KEY}': ${ACTUAL}"

if [ "${ACTUAL}" -eq "${EXPECTED}" ] 2>/dev/null; then
	echo "VERDICT: PASS (shared cache behavior)"
	exit 0
else
	echo "VERDICT: FAIL (not shared or unexpected value)" >&2
	exit 1
fi
