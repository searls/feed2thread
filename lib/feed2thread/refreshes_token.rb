module Feed2Thread
  class RefreshesToken
    def refresh!(config, options)
      return unless config.access_token_refreshed_at.nil? ||
        config.access_token_refreshed_at < Time.now - (60 * 60)

      puts "Refreshing Threads access token" if options.verbose
      data = Http.get("/refresh_access_token", {
        grant_type: "th_refresh_token",
        access_token: config.access_token
      })

      config.access_token = data[:access_token]
      config.access_token_refreshed_at = Time.now.utc

      puts "Updating Threads access token in: #{options.config_path}" if options.verbose
      File.write(options.config_path, config.as_yaml)
    end
  end
end
