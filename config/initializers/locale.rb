# frozen_string_literal: true

# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
I18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{yml}")]

# Set default locale not to :en
I18n.default_locale = :vi

# Set available locales
I18n.available_locales = %i[vi en]
