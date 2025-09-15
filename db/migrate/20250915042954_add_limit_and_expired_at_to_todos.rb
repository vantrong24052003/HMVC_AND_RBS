class AddLimitAndExpiredAtToTodos < ActiveRecord::Migration[8.0]
  def change
    add_column :todos, :limit, :integer, comment: "Số phút giới hạn cho todo"
    add_column :todos, :expired_at, :datetime, comment: "Thời gian hết hạn của todo"

    add_index :todos, :expired_at
  end
end
