global_config = YAML.load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)[Rails.env].with_indifferent_access

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{global_config[:host]}:#{global_config[:port]}/12" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{global_config[:host]}:#{global_config[:port]}/12" }
end