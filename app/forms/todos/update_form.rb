# frozen_string_literal: true

# Created at: 2025-08-31 06:34 +0700
# Creator: trongdn2405@gmail.com

class Todos::UpdateForm < ApplicationForm
  attribute :title, :string
  attribute :description, :string
  attribute :priority, :string
  attribute :status, :string
  attribute :limit, :integer
  attribute :started_at, :datetime
  attribute :schedules

  validates :title, presence: true
  validates :description, presence: true
end
