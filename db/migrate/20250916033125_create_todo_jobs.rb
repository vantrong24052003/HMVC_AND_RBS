class CreateTodoJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :todo_jobs do |t|
      t.bigint :todo_id, null: false
      t.bigint :status, null: false
      t.json :error
      t.timestamps
      t.datetime :deleted_at

      t.index [ :todo_id ]
      t.index [ :status ]
    end

    add_foreign_key :todo_jobs, :todos
  end
end
