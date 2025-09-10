# frozen_string_literal: true

# Created at: 2025-08-31 06:34 +0700
# Creator: trongdn2405@gmail.com

class Todos::NewOperation < ApplicationOperation
  attr_reader :form

  def call
    step_build_form
  end

  private

  def step_build_form
    @form = Todos::NewForm.new
  end
end
