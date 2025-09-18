# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

class Notifications::SlackNotifier
  def self.notify(text)
    url = ENV["SLACK_WEBHOOK_URL"].to_s
    raise "SLACK_WEBHOOK_URL is not set" if url.strip.empty?

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request.body = { text: text }.to_json
    response = http.request(request)
    raise "Slack webhook failed with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    true
  end
end
