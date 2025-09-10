# frozen_string_literal: true

# Created at: 2025-08-31 06:34 +0700
# Creator: trongdn2405@gmail.com

class Todos::UpdateOperation < ApplicationOperation
  attr_reader :form

  def call
    step_build_form { return }
    step_update_todo
  end

  private

  def step_build_form
    @form = Todos::UpdateForm.new(permit_params)
    return if @form.valid?

    yield
  end

  def step_update_todo
    @todo = Todo.find(params[:id])
    @todo.update(permit_params)
  end

  def permit_params
    params.require(:todo).permit(:title, :description, :priority, :status)
  end
end
