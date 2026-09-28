Rails.application.routes.draw do
  root "pages#home"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :users, only: %i[new create]

  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout
end
