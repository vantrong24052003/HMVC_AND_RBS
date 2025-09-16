# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has()
  allow_browser versions: :modern

  before_action :set_locale

  protected

  def set_locale
    I18n.locale =
      if %w[vi en].include?(params[:locale])
        params[:locale]
      else
        I18n.default_locale
      end
  end

  def default_url_options(options = {})
    { locale: I18n.locale }.merge options
  end
end
