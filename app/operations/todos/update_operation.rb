# frozen_string_literal: true

# Created at: 2025-08-31 06:34 +0700
# Creator: trongdn2405@gmail.com

class Todos::UpdateOperation < ApplicationOperation
  attr_reader :form, :todo

  def call
    step_build_form { return }
    step_update_todo
  end

  private

  def step_build_form
    @todo = Todo.find(params[:id])
    @form = Todos::UpdateForm.new(permit_params.except(:tasks_attributes))
    return if @form.valid?

    yield
  end

  def step_update_todo
    payload = @form.attributes

    if permit_params[:tasks_attributes].present?
      payload[:tasks_attributes] = permit_params[:tasks_attributes]
    end

    @todo.update(payload)
    @form.errors.merge!(@todo.errors) if @todo.errors.any?
  end

  def permit_params
    params.require(:todo).permit(
      :title, :description, :priority, :status, :limit, :started_at,
      schedules:        {},
      tasks_attributes: %i[id title description priority status duration_minutes _destroy],
    )
  end
end
