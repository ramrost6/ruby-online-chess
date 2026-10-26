Rails.application.routes.draw do
  get "/favicon.ico", to: ->(_env) {
    [204, { "Content-Type" => "image/x-icon", "Cache-Control" => "public, max-age=86400" }, []]
  }
  get "/.well-known/appspecific/com.chrome.devtools.json", to: ->(_env) {
    [204, { "Content-Type" => "application/json", "Cache-Control" => "no-store" }, []]
  }

  mount ActionCable.server => "/cable"
  root "pages#home"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :users, only: %i[new create]
  resources :games, only: :show
  resources :lobbies, only: %i[show create] do
    post :join, on: :collection
  end
  get "/games/:id/state", to: "games#state", as: :game_state
  post "/games/:id/move", to: "games#move", as: :game_move
  post "/games/:id/resign", to: "games#resign", as: :game_resign

  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout
end
