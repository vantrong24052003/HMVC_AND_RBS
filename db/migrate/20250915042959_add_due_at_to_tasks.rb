class AddDueAtToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :due_at, :datetime

    add_index :tasks, :due_at
  end
end
