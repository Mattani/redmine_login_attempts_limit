#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

ROOT = File.expand_path('..', __dir__) # plugin root (repo)

# Prefer current working directory as Redmine root, fall back to plugin path
cwd_path = File.join(Dir.pwd, 'config', 'environments', 'production.rb')
plugin_path = File.join(ROOT, 'config', 'environments', 'production.rb')

if File.exist?(cwd_path)
  path = cwd_path
  origin = :cwd
elsif File.exist?(plugin_path)
  path = plugin_path
  origin = :plugin
else
  $stderr.puts "ERROR: production.rb not found in current directory (#{cwd_path}) or plugin path (#{plugin_path})"
  exit 1
end

lines = File.read(path).lines
changed = false
changed_items = []

# Ensure config.action_controller.perform_caching = true
performed = false
lines.map! do |l|
  if l =~ /^\s*config\.action_controller\.perform_caching\s*=\s*(.*)$/
    performed = true
    current_val = $1.strip
    indent = l[/^\s*/] || ''
    if current_val == 'true'
      puts "perform_caching already set to true; leaving as-is"
      l
    else
      changed = true
      changed_items << 'perform_caching -> true'
      "#{indent}config.action_controller.perform_caching = true\n"
    end
  else
    l
  end
end

unless performed
  # try to insert after the main configure block header if present
  insert_after = lines.find_index { |l| l =~ /Rails\.application\.configure|Application\.configure/ }
  insert_pos = insert_after ? insert_after + 1 : 0
  # determine indent from the configure header line or default to two spaces
  header_indent = insert_after ? (lines[insert_after][/^\s*/] || '') : ''
  insert_indent = header_indent + '  '
  lines.insert(insert_pos, "\n#{insert_indent}config.action_controller.perform_caching = true\n")
  changed = true
  changed_items << 'insert perform_caching = true'
end

# Helper to build a cache block with proper indentation
def build_cache_block(indent)
  inner = indent + '  '
  [].tap do |a|
    a << "#{indent}# Use Redis as Rails.cache (added by scripts/configure_production_redis.rb)\n"
    a << "#{indent}config.cache_store = :redis_cache_store, {\n"
    a << "#{inner}url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',\n"
    a << "#{inner}namespace: 'redmine_cache',\n"
    a << "#{inner}reconnect_attempts: 1\n"
    a << "#{indent}}\n"
  end.join
end

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
    existing_block = lines[start_idx..end_idx].join
    if existing_block =~ /redis_cache_store/
      puts "config.cache_store already uses redis_cache_store; skipping modification"
    else
      lines.slice!(start_idx..end_idx)
      # preserve indentation of the original start line
      indent = lines[start_idx][/^\s*/] || ''
      lines.insert(start_idx, build_cache_block(indent))
      changed = true
      changed_items << 'replace cache_store with redis_cache_store'
    end
  else
    # fallback: inspect a few lines to see if redis appears
    sample = lines[start_idx, 5].join
    if sample =~ /redis_cache_store/
      puts "config.cache_store already uses redis_cache_store; skipping modification"
    else
      lines.slice!(start_idx)
      indent = lines[start_idx][/^\s*/] || ''
      lines.insert(start_idx, build_cache_block(indent))
      changed = true
      changed_items << 'replace cache_store with redis_cache_store'
    end
  end
else
  pc_idx = lines.find_index { |l| l =~ /^\s*config\.action_controller\.perform_caching\s*=\s*/ }
  insert_pos = pc_idx ? pc_idx + 1 : lines.size
  indent = pc_idx ? (lines[pc_idx][/^\s*/] || '') : ''
  lines.insert(insert_pos, "\n" + build_cache_block(indent))
  changed = true
  changed_items << 'insert cache_store redis_cache_store'
end

if changed
  backup = "#{path}.bak.#{Time.now.strftime('%Y%m%d%H%M%S')}"
  FileUtils.cp(path, backup)
  File.write(path, lines.join)
  puts "Updated #{path}. Backup created at #{backup}"
  puts "Changes applied: #{changed_items.join(', ')}"
  if origin == :cwd
    puts "Script was run from Redmine root (#{Dir.pwd}) and updated production.rb there."
  else
    puts "Script updated production.rb inside the plugin at #{plugin_path}. If you intended to modify your Redmine app, run this script from the Redmine root: \n  ruby plugins/redmine_login_attempts_limit/scripts/configure_production_redis.rb"
  end
else
  puts "No changes required. production.rb already has perform_caching=true and/or redis cache_store where applicable."
end
