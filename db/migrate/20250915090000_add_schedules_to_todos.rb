# frozen_string_literal: true

class AddSchedulesToTodos < ActiveRecord::Migration[8.0]
  def change
    add_column :todos, :schedules, :json
  end
end
