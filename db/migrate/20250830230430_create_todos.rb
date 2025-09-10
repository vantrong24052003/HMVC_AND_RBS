# frozen_string_literal: true

class CreateTodos < ActiveRecord::Migration[8.0]
  def change
    create_table :todos do |t|
      t.string :title
      t.string :description
      t.integer :priority
      t.integer :status

      t.timestamps
    end
  end
end
