# frozen_string_literal: true

class TodosJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.minutes, queue: :low_priority

  def perform(todo_id)
    todo = Todo.includes(:tasks).find_by(id: todo_id)

    tasks = todo.tasks.to_a

    Notifications::SlackNotifier.notify_with_blocks(build_blocks(todo, tasks))
  end

  private

  def build_blocks(todo, tasks)
    priority_emoji = { "high" => "🔴", "medium" => "🟡" }.fetch(todo.priority, "🟢")

    header_sections = [
      { type: "header", text: { type: "plain_text", text: "#{priority_emoji} #{todo.title}" } },
      { type: "section", text: { type: "mrkdwn", text: "*Description:*\n#{todo.description}" } },
      { type: "section", fields: [
        { type: "mrkdwn", text: "*Status:*\n`#{todo.status}`" },
        { type: "mrkdwn", text: "*Priority:*\n`#{todo.priority}`" },
      ], },
    ]

    header_sections + build_task_sections(todo, tasks)
  end

  def build_task_sections(todo, tasks)
    {
      "*Pending:*"     => tasks.select { |t| t.status == "pending" },
      "*In progress:*" => tasks.select { |t| t.status == "progress" },
      "*Completed:*"   => tasks.select { |t| t.status == "done" },
    }.filter_map do |title, group_tasks|
      next if group_tasks.empty?

      task_lines = group_tasks.map { |task| format_task_line(todo, task) }
      { type: "section", text: { type: "mrkdwn", text: "#{title}\n#{task_lines.join("\n")}" } }
    end
  end

  def format_task_line(todo, task)
    status_emoji = case task.status
                   when "pending" then "⏳"
                   when "progress" then "🔄"
                   when "done" then "✅"
                   else ""
                   end
    time_range = calculate_time_range(todo, task)

    "*#{task.title}*\n#{status_emoji} _#{task.description}_\n   `Status:` #{task.status} | `Time:` #{time_range}"
  end

  def calculate_time_range(todo, task)
    return "no time info" unless task.duration_minutes && todo.started_at

    start_time = todo.started_at.strftime("%d/%m %H:%M")
    end_time = (todo.started_at + task.duration_minutes.minutes).strftime("%d/%m %H:%M")
    "#{start_time} ~ #{end_time}"
  end
end
