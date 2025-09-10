# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title
      t.string :description
      t.integer :priority
      t.integer :status
      t.references :todo, null: false, foreign_key: true

      t.timestamps
    end
  end
end
