class AddStartedAtToTodos < ActiveRecord::Migration[8.0]
  def change
    add_column :todos, :started_at, :datetime
  end
end
