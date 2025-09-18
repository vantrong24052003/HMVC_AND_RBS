class TodosJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.minutes, queue: :low_priority

  def perform(todo_id)
    todo = Todo.includes(:tasks).find_by(id: todo_id)
    return if todo.nil?
    return if !%w[pending progress].include?(todo.status)

    tasks = todo.tasks.select { |t| %w[pending progress].include?(t.status) }
    return if tasks.empty?

    message = build_message(todo, tasks)
    Notifications::SlackNotifier.notify(message)
  end

  private

  def build_message(todo, tasks)
    lines = []
    lines << "Todo: #{todo.title} (##{todo.id})"
    lines << "Status: #{todo.status} | Priority: #{todo.priority}"
    lines << "Tasks:"
    tasks.each_with_index do |task, idx|
      lines << "#{idx + 1}. [#{task.status}] #{task.title}"
    end
    lines.join("\n")
  end
end
