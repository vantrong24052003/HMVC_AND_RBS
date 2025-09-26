# frozen_string_literal: true

Rails.root.glob("app/constants/*.rb").each { |file| require file }
