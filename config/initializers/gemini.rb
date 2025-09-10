# frozen_string_literal: true

Rails.application.config.x.gemini = {
  api_key: Rails.application.credentials.dig(:gemini, :api_key),
  default_model: "gemini-1.5-flash",
  models: {
    flash: "gemini-1.5-flash",
    pro: "gemini-1.5-pro"
  },
  endpoint_template: "https://generativelanguage.googleapis.com/v1/models/%<model>s:generateContent"
}
