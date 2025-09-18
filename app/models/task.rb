class Task < ApplicationRecord
  belongs_to :todo

  enumerize :priority, in: { low: 0, medium: 1, high: 2 }, i18n_scope: "activerecord.enums.task.priority"
  enumerize :status, in: { pending: 0, progress: 1, done: 2 }, i18n_scope: "activerecord.enums.task.status"

  validates :title, presence: true
  validates :description, presence: true

  scope :overdue, -> { where("due_at < ?", Time.current) }
  scope :upcoming, -> { where("due_at > ?", Time.current) }
  scope :with_due_date, -> { where.not(due_at: nil) }

  def overdue?
    due_at.present? && due_at < Time.current
  end

  def upcoming?
    due_at.present? && due_at > Time.current
  end
end
