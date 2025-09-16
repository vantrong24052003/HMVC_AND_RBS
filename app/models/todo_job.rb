# frozen_string_literal: true

class TodoJob < ApplicationRecord
  belongs_to :todo

  enumerize :status, in: { pending: 0, in_progress: 1, completed: 2, failed: 3 }

  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end
end
