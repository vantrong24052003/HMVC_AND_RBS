# frozen_string_literal: true

ALLOWED_STATUSES = %w[pending progress].freeze

namespace :todos do
  desc "Dispatch daily scheduled todos"
  task "dispatch:daily" => :environment do
    Todo.where(status: ALLOWED_STATUSES)
      .where("(schedules ->> 'interval') = ?", "daily")
      .find_in_batches(batch_size: 1000) do |group|
      group.each do |todo|
        TodosJob.perform_later(todo.id) if schedule_due_now?(todo.schedules)
      end
    end
  end

  desc "Dispatch weekly scheduled todos"
  task "dispatch:weekly" => :environment do
    Todo.where(status: ALLOWED_STATUSES)
      .where("(schedules ->> 'interval') = ?", "weekly")
      .find_in_batches(batch_size: 1000) do |group|
      group.each do |todo|
        TodosJob.perform_later(todo.id) if schedule_due_now?(todo.schedules)
      end
    end
  end

  desc "Dispatch monthly scheduled todos"
  task "dispatch:monthly" => :environment do
    Todo.where(status: ALLOWED_STATUSES)
      .where("(schedules ->> 'interval') = ?", "monthly")
      .find_in_batches(batch_size: 1000) do |group|
      group.each do |todo|
        TodosJob.perform_later(todo.id) if schedule_due_now?(todo.schedules)
      end
    end
  end
end


def schedule_due_now?(schedules)
  interval = schedules["interval"].to_s
  now = Time.zone.now
  hour = schedules["hour"].to_i
  minute = schedules["minute"].to_i

  case interval
  when "daily"
    now.hour == hour && now.min == minute
  when "weekly"
    weekday = schedules["weekday"].to_i
    now.wday == weekday && now.hour == hour && now.min == minute
  when "monthly"
    day = schedules["day"].to_i
    now.day == day && now.hour == hour && now.min == minute
  else
    false
  end
end
