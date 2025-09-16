class Todo < ApplicationRecord
  has_many :tasks, dependent: :destroy
  accepts_nested_attributes_for :tasks, allow_destroy: true

  enumerize :priority, in: { low: 0, medium: 1, high: 2 }
  enumerize :status, in: { pending: 0, progress: 1, done: 2 }

  validates :limit, numericality: { greater_than: 0 }, allow_nil: true
  validate :validate_total_task_duration_within_limit

  before_validation :normalize_weekday
  before_save :set_expired_at, if: -> { started_at_changed? || limit_changed? }

  scope :expired, -> { where("expired_at <= ?", Time.zone.now) }
  scope :active, -> { where("expired_at > ? OR expired_at IS NULL", Time.zone.now) }

  def expired?
    expired_at.present? && expired_at <= Time.zone.now
  end

  def active?
    !expired?
  end


  private

  def set_expired_at
    return self.expired_at = started_at + limit.minutes if limit.present? && started_at.present?
    self.expired_at = nil
  end

  def validate_total_task_duration_within_limit
    return if limit.blank? || limit.to_i <= 0 || tasks.blank?

    total = tasks.reject(&:marked_for_destruction?).sum { |t| t.duration_minutes.to_i }
    if total > limit.to_i
      errors.add(:base, "Tổng thời lượng tasks (#{total} phút) vượt giới hạn todo (#{limit} phút)")
    end
  end

  WEEKDAY_INDEX = { "sunday" => 0, "monday" => 1, "tuesday" => 2, "wednesday" => 3, "thursday" => 4, "friday" => 5, "saturday" => 6 }.freeze

  def normalize_weekday
    return if schedules.blank? || schedules["interval"] != "weekly"

    value = schedules["weekday"]
    if value.blank?
      errors.add(:schedules, "weekday is required for weekly schedule")
      return
    end

    idx = WEEKDAY_INDEX[value.to_s.downcase]
    if idx.nil?
      errors.add(:schedules, "weekday invalid")
    else
      schedules["weekday"] = idx
    end
  end

  # create todo to list, option target: "todos" is the id of the list in the view (index.html.erb)
  after_create_commit -> { broadcast_append_to :todos, target: "todos" }

  # update todo in list, option target: "todos" is the id of the list in the view (index.html.erb)
  after_update_commit -> { broadcast_replace_to :todos }

  # remove todo from list
  after_destroy_commit -> { broadcast_remove_to :todos }
end
