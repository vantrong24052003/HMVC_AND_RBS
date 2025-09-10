# frozen_string_literal: true

module ApplicationHelper
  def asset_exists?(path)
    Rails.application.assets_manifest.assets[path].present?
  rescue StandardError
    false
  end
end
