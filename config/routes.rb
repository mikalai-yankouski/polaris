Rails.application.routes.draw do
  root "zones#index"

  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[new create]

  resources :zones, only: %i[index show] do
    resources :reservations, only: :create
  end
  resources :reservations, only: %i[index] do
    member { post :cancel }
  end

  namespace :admin do
    root "dashboard#show"
    resources :reservations, only: :index do
      member do
        post :confirm
        post :decline
        post :cancel
        post :complete
      end
    end
    resources :zones, except: :show
    resources :amenities, only: %i[index create edit update destroy]
    resources :users, only: %i[index update]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
