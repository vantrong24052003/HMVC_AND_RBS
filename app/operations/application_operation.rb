# frozen_string_literal: true

# Created at: 2025-08-26 06:22 +0700
# Creator: trongdn2405@gmail.com

class ApplicationOperation
  attr_reader :params, :current_user

  def initialize(params, data = {})
    @params       = params
    @current_user = data[:current_user]
  end
end
