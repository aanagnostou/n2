require 'feed_parser'

namespace :n2 do
  namespace :feeds do
    namespace :parse do
      desc "Parse All Feeds"
      task :all => :environment do
        feeds = Feed.find(:all, :conditions => ["specialType = ?", "default"])

        feeds.each { |f| update_feed f }
      end

      desc "Parse One Feed from 'feed_id'"
      task :one => :environment do
        raise "This task expects feed_id to be provied with an integer" unless ENV.include?("feed_id")
        feed = Feed.find_by_id ENV["feed_id"]
        raise "Invalid feed id." unless feed.present?

        update_feed feed
      end
    end
  end
end

def update_feed(feed)
  begin
     rss = RSS::Parser.parse(open(feed.rss).read, false)
     rss = FeedParser.new(feed.rss)
  rescue => e
    puts "Failed to open feed at #{feed.url} -- #{e}"
    return false
  end

  puts "The feed #{feed.title}(#{feed.url}) is presently invalid." or return false unless rss.present?
  puts "The feed #{feed.title}(#{feed.url}) is presently empty." or return false unless rss.items.present?

  puts "Parsing #{feed.title} with #{rss.items.size} items -- updated on #{rss.date}"

  feed_date = feed.last_fetched_at || feed.updated_at || feed.created_at
  if rss.date and feed_date < rss.date
    rss.items.each do |item|
      break if item[:date] <= feed_date
      next unless item[:body] and item[:link] and item[:title] and item[:date]

      puts "\tCreating newswire for \"#{item[:title].chomp}\""

      Newswire.create!({
        :title      => item[:title],
        :caption    => item[:body],
        :created_at => item[:date].to_s,
        :url        => item[:link],
        :imageUrl   => item[:image],
        :feed       => feed
      })
    end

    feed.update_attributes({:updated_at => Time.now, :last_fetched_at => rss.date.to_s})
  end
end