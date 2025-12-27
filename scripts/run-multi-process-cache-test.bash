#!/usr/bin/env bash
# Run two concurrent processes of the multi_process_cache_test.rb script to observe shared cache behavior.
# Usage:
# TEST_CACHE=redis REDIS_URL=redis://localhost:6379/1 RAILS_ENV=test ./scripts/run-multi-process-cache-test.bash multi-test 100 0.05

set -e
KEY=${1:-multi-test}
ITERATIONS=${2:-100}
DELAY=${3:-0.05}

echo "Starting two concurrent runners: key=${KEY} iterations=${ITERATIONS} delay=${DELAY}"

# Start first in background
TEST_CACHE=${TEST_CACHE:-} REDIS_URL=${REDIS_URL:-} RAILS_ENV=test bundle exec rails runner "load 'scripts/multi_process_cache_test.rb'; ARGV.replace(['${KEY}','${ITERATIONS}','${DELAY}']); exec(ARGV)" &
PID1=$!

# Small stagger
sleep 0.2

# Start second in foreground
TEST_CACHE=${TEST_CACHE:-} REDIS_URL=${REDIS_URL:-} RAILS_ENV=test bundle exec rails runner "load 'scripts/multi_process_cache_test.rb'; ARGV.replace(['${KEY}','${ITERATIONS}','${DELAY}']); exec(ARGV)"

wait $PID1

echo "Both processes finished."
