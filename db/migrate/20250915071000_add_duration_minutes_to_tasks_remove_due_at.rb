class AddDurationMinutesToTasksRemoveDueAt < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :duration_minutes, :integer
    remove_index :tasks, :due_at
    remove_column :tasks, :due_at, :datetime
  end
end
