require "yaml"
require "time"

module Feed2Thread
  Config = Struct.new(
    :feed_url,
    :threads_app_id,
    :threads_app_secret,
    :threads_user_id,
    :access_token,
    :access_token_refreshed_at,
    keyword_init: true
  ) do
    def as_yaml
      to_h.transform_keys(&:to_s).to_yaml.gsub(/^---\n/, "")
    end
  end

  class LoadsConfig
    def load(options)
      puts "Loading config from: #{options.config_path}" if options.verbose
      yaml = YAML.load_file(options.config_path, permitted_classes: [Time])
      Config.new(**yaml)
    end
  end
end
