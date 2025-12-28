#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

ROOT = File.expand_path('..', __dir__) # repo/scripts -> repo
path = File.join(ROOT, 'config', 'environments', 'production.rb')

unless File.exist?(path)
  $stderr.puts "ERROR: production.rb not found at #{path}"
  exit 1
end

backup = "#{path}.bak.#{Time.now.strftime('%Y%m%d%H%M%S')}"
FileUtils.cp(path, backup)

lines = File.read(path).lines

# Ensure config.action_controller.perform_caching = true
performed = false
lines.map! do |l|
  if l =~ /^\s*config\.action_controller\.perform_caching\s*=\s*/
    performed = true
    # keep same indentation as original if possible
    indent = l[/^\s*/] || ''
    "#{indent}config.action_controller.perform_caching = true\n"
  else
    l
  end
end

unless performed
  # try to insert after the main configure block header if present
  insert_after = lines.find_index { |l| l =~ /Rails\.application\.configure|Application\.configure/ }
  insert_pos = insert_after ? insert_after + 1 : 0
  lines.insert(insert_pos, "\n  config.action_controller.perform_caching = true\n")
end

# Prepare redis cache_store block
cache_block = <<~RUBY
  # Use Redis as Rails.cache (added by scripts/configure_production_redis.rb)
  config.cache_store = :redis_cache_store, {
    url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
    namespace: 'redmine_cache',
    reconnect_attempts: 1
  }
RUBY

# Find existing config.cache_store and replace; otherwise insert after perform_caching
start_idx = lines.find_index { |l| l =~ /^\s*config\.cache_store\s*=\s*/ }
if start_idx
  # find end of block (look ahead for a line with a closing brace at column start)
  end_idx = nil
  (start_idx..[lines.size - 1, start_idx + 40].min).each do |i|
    if lines[i] =~ /^\s*}\s*$/
      end_idx = i
      break
    end
  end
  if end_idx
    lines.slice!(start_idx..end_idx)
  else
    # fallback: remove just the start line
    lines.slice!(start_idx)
  end
  lines.insert(start_idx, cache_block)
else
  pc_idx = lines.find_index { |l| l =~ /^\s*config\.action_controller\.perform_caching\s*=\s*/ }
  insert_pos = pc_idx ? pc_idx + 1 : lines.size
  lines.insert(insert_pos, "\n" + cache_block)
end

File.write(path, lines.join)
puts "Updated #{path}. Backup created at #{backup}"
