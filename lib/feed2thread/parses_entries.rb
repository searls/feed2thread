require "nokogiri"
require "open-uri"

module Feed2Thread
  Post = Struct.new(:url, :text, keyword_init: true)

  class ParsesEntries
    def parse(feed_url)
      feed = Nokogiri::XML(URI.parse(feed_url).open)
      feed.xpath("//*:entry").map { |entry|
        Post.new(
          url: entry.xpath("*:link[@rel='alternate'][1]/@href").text,
          text: entry.xpath("*:title[1]").text
        )
      }
    end
  end
end
