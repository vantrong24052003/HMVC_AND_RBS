# frozen_string_literal: true

# Force load dotenv for staging environment
if Rails.env.development? || Rails.env.staging? || Rails.env.production? || Rails.env.test?
  Dotenv.overload(".env.#{Rails.env}", ".env")
end
