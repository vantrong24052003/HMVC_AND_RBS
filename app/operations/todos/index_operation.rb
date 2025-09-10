# frozen_string_literal: true

# Created at: 2025-08-31 06:34 +0700
# Creator: trongdn2405@gmail.com

class Todos::IndexOperation < ApplicationOperation
  attr_reader :form

  def call
    step_get_todos
  end

  private

  def step_get_todos
    @form = Todo.all
  end
end
