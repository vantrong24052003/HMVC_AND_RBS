# frozen_string_literal: true

# Created at: 2025-08-31 06:34 +0700
# Creator: trongdn2405@gmail.com

class Todos::DestroyOperation < ApplicationOperation
  attr_reader :todo

  def call
    step_destroy_todo
  end

  private

  def step_destroy_todo
    @todo = Todo.find(params[:id])
    @todo.destroy
  end
end
