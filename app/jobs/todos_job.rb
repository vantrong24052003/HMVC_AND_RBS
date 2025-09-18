class TodosJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.minutes, queue: :low_priority

  def perform(todo_id)
    todo = Todo.includes(:tasks).find_by(id: todo_id)
    return Rails.logger.info "Todo not found" if todo.nil?
    return Rails.logger.info "Todo status not active: #{todo.status}" unless %w[pending progress].include?(todo.status)

    tasks = todo.tasks.select { |t| %w[pending progress].include?(t.status) }
    return Rails.logger.info "No active tasks found" if tasks.empty?

    Rails.logger.info "Sending notification for todo: #{todo.title} with #{tasks.count} tasks"
    Notifications::SlackNotifier.notify_with_blocks(build_blocks(todo, tasks))
  end

  private

  def build_blocks(todo, tasks)
    priority_emoji = { "high" => "🔴", "medium" => "🟡" }.fetch(todo.priority, "🟢")
    task_list = tasks.map do |task|
      format_task_line(todo, task)
    end.join("\n")

    [
      { type: "header", text: { type: "plain_text", text: "#{priority_emoji} #{todo.title}" } },
      { type: "section", text: { type: "mrkdwn", text: "*Description:*\n#{todo.description}" } },
      { type: "section", fields: [
        { type: "mrkdwn", text: "*Status:*\n`#{todo.status}`" },
        { type: "mrkdwn", text: "*Priority:*\n`#{todo.priority}`" }
      ] },
      { type: "section", text: { type: "mrkdwn", text: "*Tasks:*\n#{task_list}" } }
    ]
  end

  def format_task_line(todo, task)
    status_emoji = task.status == "pending" ? "⏳" : "🔄"
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
