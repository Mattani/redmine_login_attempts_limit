#!/usr/bin/env bash
# Run two concurrent processes of the multi_process_cache_test.rb script to observe shared cache behavior.
# Usage:
# TEST_CACHE=redis REDIS_URL=redis://localhost:6379/1 RAILS_ENV=test ./scripts/run-multi-process-cache-test.bash multi-test 100 0.05

set -e
KEY=${1:-multi-test}
ITERATIONS=${2:-50}
DELAY=${3:-0.1}

echo "Starting two concurrent runners: key=${KEY} iterations=${ITERATIONS} delay=${DELAY}"

# Number of concurrent processes started by this script
PROCESSES=2
EXPECTED=$((ITERATIONS * PROCESSES))

echo "Expected final value (if cache is shared): ${EXPECTED}"

# Start first in background
TEST_CACHE=${TEST_CACHE:-} REDIS_URL=${REDIS_URL:-} RAILS_ENV=test bundle exec rails runner "script = Rails.root.join('plugins','redmine_login_attempts_limit','scripts','multi_process_cache_test.rb').to_s; require script; MultiProcessCacheTest.run('${KEY}','${ITERATIONS}','${DELAY}')" &
PID1=$!

# Small stagger
sleep 0.2

# Start second in foreground
TEST_CACHE=${TEST_CACHE:-} REDIS_URL=${REDIS_URL:-} RAILS_ENV=test bundle exec rails runner "script = Rails.root.join('plugins','redmine_login_attempts_limit','scripts','multi_process_cache_test.rb').to_s; require script; MultiProcessCacheTest.run('${KEY}','${ITERATIONS}','${DELAY}')"

wait $PID1

echo "Both processes finished."

# Read actual cache value using same cache settings
ACTUAL=$(TEST_CACHE=${TEST_CACHE:-} REDIS_URL=${REDIS_URL:-} MPC_KEY=${KEY} RAILS_ENV=test bundle exec rails runner "puts (Rails.cache.read(ENV['MPC_KEY']).to_i rescue 0)")

echo "Actual final cache value for key='${KEY}': ${ACTUAL}"

if [ "${ACTUAL}" -eq "${EXPECTED}" ] 2>/dev/null; then
	echo "VERDICT: PASS (shared cache behavior)"
else
	echo "VERDICT: FAIL (not shared or unexpected value)"
fi
