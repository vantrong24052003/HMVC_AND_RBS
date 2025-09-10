# frozen_string_literal: true

Dir[Rails.root.join("app", "constants", "*.rb")].sort.each { |file| require file }
