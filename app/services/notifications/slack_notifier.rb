# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

class Notifications::SlackNotifier
  def self.notify(text)
    send_message({ text: text })
  end

  def self.notify_with_blocks(blocks)
    send_message({ blocks: blocks })
  end

  private

  def self.send_message(payload)
    url = ENV["SLACK_WEBHOOK_URL"].to_s
    raise "SLACK_WEBHOOK_URL is not set" if url.strip.empty?

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = http.request(request)
    raise "Slack webhook failed with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    true
  end
end
