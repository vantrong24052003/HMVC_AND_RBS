# frozen_string_literal: true

class AddLimitAndExpiredAtToTodos < ActiveRecord::Migration[8.0]
  def change
    add_column :todos, :limit, :integer
    add_column :todos, :expired_at, :datetime

    add_index :todos, :expired_at
  end
end
