# frozen_string_literal: true

class Todo < ApplicationRecord
  has_many :tasks, dependent: :destroy
  has_many :todo_jobs, dependent: :destroy
  accepts_nested_attributes_for :tasks, allow_destroy: true

  enumerize :priority, in: { low: 0, medium: 1, high: 2 }, i18n_scope: "activerecord.enums.todo.priority"
  enumerize :status, in: { pending: 0, progress: 1, done: 2 }, i18n_scope: "activerecord.enums.todo.status"

  validates :limit, numericality: { greater_than: 0 }, allow_nil: true
  validate :validate_total_task_duration_within_limit

  before_validation :normalize_weekday
  before_save :set_expired_at, if: -> { started_at_changed? || limit_changed? }

  scope :expired, -> { where(expired_at: ..Time.zone.now) }
  scope :active, -> { where("expired_at > ? OR expired_at IS NULL", Time.zone.now) }

  def expired?
    expired_at.present? && expired_at <= Time.zone.now
  end

  def active?
    !expired?
  end

  def display_schedule
    return nil unless valid_schedule?

    hour = schedules["hour"] || 0
    minute = (schedules["minute"] || 0).to_s.rjust(2, "0")

    case schedules["interval"]
    when "daily" then I18n.t("activerecord.attribute_values.todo.schedule.daily", hour:, minute:)
    when "weekly" then format_weekly_schedule(hour, minute)
    when "monthly" then format_monthly_schedule(hour, minute)
    end
  end

  def valid_schedule?
    schedules.present? && schedules["interval"].present?
  end

  def format_weekly_schedule(hour, minute)
    weekday = schedules["weekday"]
    return nil if weekday.blank?

    day_name = I18n.t("activerecord.attribute_values.todo.day_name.#{weekday}")
    I18n.t("activerecord.attribute_values.todo.schedule.weekly", day: day_name, hour:, minute:)
  end

  def format_monthly_schedule(hour, minute)
    day = schedules["day"]
    return nil if day.blank?

    I18n.t("activerecord.attribute_values.todo.schedule.monthly", day:, hour:, minute:)
  end

  WEEKDAY_INDEX = {
    "sunday" => 0, "monday" => 1, "tuesday" => 2, "wednesday" => 3,
    "thursday" => 4, "friday" => 5, "saturday" => 6,
  }.freeze

  private

  def set_expired_at
    return self.expired_at = started_at + limit.minutes if limit.present? && started_at.present?
    self.expired_at = nil
  end

  def validate_total_task_duration_within_limit
    return if limit.blank? || limit.to_i <= 0 || tasks.blank?

    total = tasks.reject(&:marked_for_destruction?).sum { |t| t.duration_minutes.to_i }
    if total > limit.to_i
      errors.add(:base,
                 I18n.t("activerecord.errors.models.todo.attributes.base.total_task_duration_exceeds_limit", total:,
                                                                                                             limit:,),)
    end
  end

  def normalize_weekday
    return unless schedules.present? && schedules["interval"] == "weekly"

    value = schedules["weekday"]
    return add_weekday_error(:weekday_required) if value.blank?

    idx = WEEKDAY_INDEX[value.to_s.downcase]
    idx.nil? ? add_weekday_error(:weekday_invalid) : schedules["weekday"] = idx
  end

  def add_weekday_error(key)
    errors.add(:schedules, I18n.t("activerecord.errors.models.todo.attributes.schedules.#{key}"))
  end

  # create todo to list, option target: "todos" is the id of the list in the view (index.html.erb)
  after_create_commit -> { broadcast_append_to :todos, target: "todos" }

  # update todo in list, option target: "todos" is the id of the list in the view (index.html.erb)
  after_update_commit -> { broadcast_replace_to :todos }

  # remove todo from list
  after_destroy_commit -> { broadcast_remove_to :todos }
end
