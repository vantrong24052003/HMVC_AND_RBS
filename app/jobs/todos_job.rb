class TodosJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.minutes, queue: :low_priority

  def perform(todo_id)
    todo = Todo.includes(:tasks).find_by(id: todo_id)
    return Rails.logger.info "Todo not found" if todo.nil?
    return Rails.logger.info "Todo status not active: #{todo.status}" unless %w[pending progress].include?(todo.status)

    tasks = todo.tasks.to_a
    return Rails.logger.info "No tasks found" if tasks.empty?

    Rails.logger.info "Sending notification for todo: #{todo.title} with #{tasks.count} tasks"
    Notifications::SlackNotifier.notify_with_blocks(build_blocks(todo, tasks))
  end

  private

  def build_blocks(todo, tasks)
    priority_emoji = { "high" => "🔴", "medium" => "🟡" }.fetch(todo.priority, "🟢")

    pending_lines = tasks.select { |t| t.status == "pending" }.map { |t| format_task_line(todo, t) }
    progress_lines = tasks.select { |t| t.status == "progress" }.map { |t| format_task_line(todo, t) }
    done_lines = tasks.select { |t| t.status == "done" }.map { |t| format_task_line(todo, t) }

    sections = []
    sections << { type: "section", text: { type: "mrkdwn", text: "*Pending:*\n#{pending_lines.join("\n")}" } } unless pending_lines.empty?
    sections << { type: "section", text: { type: "mrkdwn", text: "*In progress:*\n#{progress_lines.join("\n")}" } } unless progress_lines.empty?
    sections << { type: "section", text: { type: "mrkdwn", text: "*Completed:*\n#{done_lines.join("\n")}" } } unless done_lines.empty?

    [
      { type: "header", text: { type: "plain_text", text: "#{priority_emoji} #{todo.title}" } },
      { type: "section", text: { type: "mrkdwn", text: "*Description:*\n#{todo.description}" } },
      { type: "section", fields: [
        { type: "mrkdwn", text: "*Status:*\n`#{todo.status}`" },
        { type: "mrkdwn", text: "*Priority:*\n`#{todo.priority}`" }
      ] }
    ] + sections
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
