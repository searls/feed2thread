module Feed2Thread
  Result = Struct.new(:post, :status, keyword_init: true)

  class PublishesPosts
    def publish(posts, config, options)
      post_limit = options.limit || posts.size
      puts "Publishing #{post_limit} posts to Threads" if options.verbose

      # reverse to post oldest first (most Atom feeds are reverse-chronological)
      posts.reverse.take(post_limit).map { |post|
        begin
          puts "Publishing thread for: #{post.url}" if options.verbose
          publish_thread(post, config, options)
        rescue => e
          warn "Failed to post #{post.url}: #{e.message}"
          e.backtrace.join("\n").each_line { |line| warn line }
          Result.new(post: post, status: :failed)
        end
      }
    end

    private

    def publish_thread(post, config, options)
      puts "Creating threads media container for Post URL - #{post.url}" if options.verbose
      container_id = Http.post("/#{config.threads_user_id}/threads", {
        media_type: "TEXT",
        text: post.text,
        access_token: config.access_token
      }.compact)[:id]

      puts "Publishing threads media container (##{container_id}) for Post URL - #{post.url}" if options.verbose
      Http.post("/#{config.threads_user_id}/threads_publish", {
        creation_id: container_id,
        access_token: config.access_token
      })
      Result.new(post: post, status: :posted)
    end
  end
end
