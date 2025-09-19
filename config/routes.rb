# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
   mount Sidekiq::Web => "/sidekiq"

  get "up" => "rails/health#show", as: :rails_health_check
  resources :todos do
    resources :tasks
  end

  root "todos#index"
end
