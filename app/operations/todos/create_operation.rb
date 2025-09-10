# frozen_string_literal: true

# Created at: 2025-08-31 06:34 +0700
# Creator: trongdn2405@gmail.com

class Todos::CreateOperation < ApplicationOperation
  attr_reader :form

  def call
    step_build_form { return }
    step_create_todo
  end

  private

  def step_build_form
    @form = Todos::CreateForm.new(permit_params)
    return if @form.valid?

    yield
  end

  def step_create_todo
    @todo = Todo.new(form.attributes)
    @todo.save
  end

  def permit_params
    params.require(:todo).permit(:title, :description, :priority, :status)
  end
end
