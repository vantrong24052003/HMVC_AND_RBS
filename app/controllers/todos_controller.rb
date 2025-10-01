# frozen_string_literal: true

# Created at: 2025-08-31 06:34 +0700
# Creator: trongdn2405@gmail.com

class TodosController < ApplicationController
  # [GET]...
  def index
    operator = Todos::IndexOperation.new(params)
    operator.call

    @form = operator.form
  end

  # [GET]...
  def show
    operator = Todos::ShowOperation.new(params)
    operator.call

    @form = operator.form
  end

  # [GET]...
  def new
    operator = Todos::NewOperation.new(params)
    operator.call

    @form = operator.form
  end

  # [GET]...
  def edit
    operator = Todos::EditOperation.new(params)
    operator.call

    @form = operator.form
    @todo = operator.todo
  end

  # [POST]...
  def create
    operator = Todos::CreateOperation.new(params)
    operator.call
    @form = operator.form
    return render :new, status: :unprocessable_entity if @form.errors.present?

    @todo = operator.todo

    respond_to do |format|
      format.html { redirect_to todos_path, notice: t("todos.flash.created_successfully") }
      format.turbo_stream { redirect_to todos_path, notice: t("todos.flash.created_successfully") }
    end
  end

  # [PUT]...
  def update
    operator = Todos::UpdateOperation.new(params)
    operator.call
    @form = operator.form
    @todo = operator.todo
    return render :edit, status: :unprocessable_entity if @form.errors.present?

    respond_to do |format|
      format.html { redirect_to todos_path, notice: t("todos.flash.updated_successfully") }
      format.turbo_stream { redirect_to todos_path, notice: t("todos.flash.updated_successfully") }
    end
  end

  # [DELETE]...
  def destroy
    operator = Todos::DestroyOperation.new(params)
    operator.call

    respond_to do |format|
      format.html { redirect_to todos_path, notice: t("todos.flash.deleted_successfully") }
      format.turbo_stream { redirect_to todos_path, notice: t("todos.flash.deleted_successfully") }
    end
  end
end
