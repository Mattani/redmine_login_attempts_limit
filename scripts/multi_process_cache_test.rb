# frozen_string_literal: true

# Usage (run with rails runner so Rails and Rails.cache are available):
# RAILS_ENV=test bundle exec rails runner scripts/multi_process_cache_test.rb KEY [ITERATIONS] [DELAY]
# Example:
# TEST_CACHE=redis REDIS_URL=redis://localhost:6379/1 RAILS_ENV=test bundle exec rails runner scripts/multi_process_cache_test.rb multi-test 100 0.1

module MultiProcessCacheTest
  module_function

  def run(key = 'multi-test', iterations = 100, delay = 0.1)
    key = key.to_s
    iterations = iterations.to_i
    delay = delay.to_f

    puts "PID=#{Process.pid} starting. key=#{key}, iterations=#{iterations}, delay=#{delay}"

    # Ensure cache is available
    unless defined?(Rails) && Rails.respond_to?(:cache) && Rails.cache
      STDERR.puts "Rails.cache is not available. Run with 'rails runner' and set RAILS_ENV=test if needed."
      return 1
    end

    iterations.times do |i|
      # Try atomic increment
      new_val = nil
      begin
        new_val = Rails.cache.increment(key, 1)
        # Some stores return nil if the key does not exist; initialize to 1 then
        if new_val.nil?
          Rails.cache.write(key, 1)
          new_val = 1
        end
      rescue StandardError
        # Some cache stores might not implement increment. fallback to read/write (racy).
        val = Rails.cache.read(key).to_i
        val += 1
        Rails.cache.write(key, val)
        new_val = val
      end

      puts "#{Time.now.iso8601} PID=#{Process.pid} iter=#{i+1} value=#{new_val}"
      STDOUT.flush
      sleep(delay)
    end

    puts "PID=#{Process.pid} finished."
    0
  end
end

# If script is called directly with rails runner, invoke run with ARGV
if __FILE__ == $PROGRAM_NAME
  exit MultiProcessCacheTest.run(ARGV[0], ARGV[1], ARGV[2])
end
