# Redis setup for production (Rails.cache)

This plugin uses `Rails.cache` to store lock/invalid-account status. When you want multiple Redmine processes to share lock state, you must configure Redmine to use Redis as the cache store in production. This document shows a short, non-exhaustive example and notes — it is an installation guide for administrators, not part of the plugin code.

## Overview

- Install and run a Redis server accessible from your Redmine host(s).
- Ensure the `redis` gem is available in Redmine's bundle.
- Configure `config/environments/production.rb` to use `:redis_cache_store`.

## Example steps

1. Install Redis (OS-specific).

Example on Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install redis-server
sudo systemctl enable --now redis-server
```

Example on RHEL/Fedora (dnf):

```bash
sudo dnf install redis -y
sudo systemctl enable --now redis
```

1. Configure `config/environments/production.rb` (example snippet):

```ruby
# Enable caching if not already
config.action_controller.perform_caching = true

# Use Redis as Rails.cache
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
  namespace: 'redmine_cache',
  reconnect_attempts: 1
}
```

Note: the plugin stores per-user lock entries with an expiry derived from the plugin settings, so setting a global `expires_in` here is optional and may confuse behavior differences; omitting `expires_in` avoids accidental overrides of the plugin's TTL.

1. Provide `REDIS_URL` to the environment for the Redmine process manager (systemd, passenger, puma, etc.). Example for systemd unit:

```ini
Environment=REDIS_URL=redis://redis-host:6379/0
```

1. Restart Redmine application processes/services.

## Testing

- You can verify the cache backend by running `rails runner` in Redmine root:

```bash
RAILS_ENV=production bundle exec rails runner "puts Rails.cache.class; puts Rails.cache.read('some-key')"
```

### Expected results

- If Redmine is correctly configured to use Redis for `Rails.cache`:

  - The first printed line will show `ActiveSupport::Cache::RedisCacheStore`.
  - If `some-key` does not exist, the read will print `nil`. If you run `Rails.cache.write('some-key', 'x', raw: true)` separately, the read will return the stored value.

- If Redmine is using FileStore or MemoryStore:

  - The printed class will be different (for example `ActiveSupport::Cache::FileStore` or `ActiveSupport::Cache::MemoryStore`).
  - FileStore and MemoryStore are not shared across processes, so multi-process lock sharing and atomic increments via `Rails.cache.increment` may not behave as expected.

## Notes & cautions

- This guide is intentionally brief. Production environments need secure Redis configuration (passwords, TLS if remote, firewall rules, monitoring, backups).
- Using Redis for cache allows atomic operations (e.g. `Rails.cache.increment`) and reliable multi-process sharing. FileStore or MemoryStore do not provide the same guarantees across processes or hosts.
- The plugin itself does not modify Redmine core config — administrators must apply these changes to their Redmine installation.

For more detailed platform-specific instructions, see the [Redis official docs](https://redis.io/).

## Automatic configuration script

If you prefer a small helper to apply the Redis cache configuration to a Redmine `production.rb`, a script is included at `plugins/redmine_login_attempts_limit/scripts/configure_production_redis.rb`.

- Location: `plugins/redmine_login_attempts_limit/scripts/configure_production_redis.rb` (run from the Redmine application root).
- What it does: creates a timestamped backup of `config/environments/production.rb`, ensures `config.action_controller.perform_caching = true`, and inserts or replaces a `config.cache_store = :redis_cache_store, { ... }` block.
- Usage:

```bash
# from Redmine application root
ruby plugins/redmine_login_attempts_limit/scripts/configure_production_redis.rb
```

- Warning: The script tries to be idempotent but cannot handle every possible `production.rb` layout; please check the backup file (created alongside the original) and review changes before deploying.
