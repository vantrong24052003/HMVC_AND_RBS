# frozen_string_literal: true

# Created at: 2025-08-31 06:34 +0700
# Creator: trongdn2405@gmail.com

class Todos::ShowOperation < ApplicationOperation
  attr_reader :form

  def call
    step_get_todo
  end

  private

  def step_get_todo
    @form = Todo.find(params[:id])
  end
end
