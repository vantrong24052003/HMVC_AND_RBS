class Todo < ApplicationRecord
  has_many :tasks, dependent: :destroy
  accepts_nested_attributes_for :tasks, allow_destroy: true

  enumerize :priority, in: { low: 0, medium: 1, high: 2 }, i18n_scope: 'activerecord.enums.todo.priority'
  enumerize :status, in: { pending: 0, progress: 1, done: 2 }, i18n_scope: 'activerecord.enums.todo.status'

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

  def display_schedule
    return nil if schedules.blank?

    interval = schedules["interval"]
    return nil if interval.blank?

    hour = schedules["hour"] || 0
    minute = (schedules["minute"] || 0).to_s.rjust(2, '0')

    case interval
    when "daily"
      I18n.t("activerecord.attribute_values.todo.schedule.daily", hour: hour, minute: minute)
    when "weekly"
      weekday = schedules["weekday"]
      if weekday.present?
        day_name = I18n.t("activerecord.attribute_values.todo.day_name.#{weekday}")
        I18n.t("activerecord.attribute_values.todo.schedule.weekly", day: day_name, hour: hour, minute: minute)
      end
    when "monthly"
      day = schedules["day"]
      if day.present?
        I18n.t("activerecord.attribute_values.todo.schedule.monthly", day: day, hour: hour, minute: minute)
      end
    end
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
      errors.add(:base, I18n.t("activerecord.errors.models.todo.attributes.base.total_task_duration_exceeds_limit", total: total, limit: limit))
    end
  end

  WEEKDAY_INDEX = { "sunday" => 0, "monday" => 1, "tuesday" => 2, "wednesday" => 3, "thursday" => 4, "friday" => 5, "saturday" => 6 }.freeze

  def normalize_weekday
    return if schedules.blank? || schedules["interval"] != "weekly"

    value = schedules["weekday"]
    if value.blank?
      errors.add(:schedules, I18n.t("activerecord.errors.models.todo.attributes.schedules.weekday_required"))
      return
    end

    idx = WEEKDAY_INDEX[value.to_s.downcase]
    if idx.nil?
      errors.add(:schedules, I18n.t("activerecord.errors.models.todo.attributes.schedules.weekday_invalid"))
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
