# frozen_string_literal: true

class AddDefaultsToTodosAndTasks < ActiveRecord::Migration[8.0]
  def change
    change_column_default :todos, :status, 0
    change_column_default :todos, :priority, 0

    change_column_default :tasks, :status, 0
    change_column_default :tasks, :priority, 0
  end
end
