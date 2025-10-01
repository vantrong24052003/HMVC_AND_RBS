# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

class Notifications::SlackNotifier
  def self.notify(text)
    send_message({ text: })
  end

  def self.notify_with_blocks(blocks)
    send_message({ blocks: })
  end

  def self.send_message(payload)
    url = ENV["SLACK_WEBHOOK_URL"].to_s
    raise "SLACK_WEBHOOK_URL is not set" if url.strip.empty?

    response = perform_http_request(url, payload)
    raise "Slack webhook failed with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    true
  end

  def self.perform_http_request(url, payload)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port).tap { |h| h.use_ssl = uri.scheme == "https" }
    request = Net::HTTP::Post.new(uri.request_uri).tap do |r|
      r["Content-Type"] = "application/json"
      r.body = payload.to_json
    end
    http.request(request)
  end
end
