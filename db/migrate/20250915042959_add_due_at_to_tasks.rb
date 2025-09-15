class AddDueAtToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :due_at, :datetime, comment: "Deadline riêng cho task (không bắt buộc)"

    add_index :tasks, :due_at
  end
end
