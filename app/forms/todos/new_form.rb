# frozen_string_literal: true

# Created at: 2025-08-31 06:34 +0700
# Creator: trongdn2405@gmail.com

class Todos::NewForm < ApplicationForm
  attribute :title, :string
  attribute :description, :string
  attribute :status, :integer
  attribute :priority, :integer

end
