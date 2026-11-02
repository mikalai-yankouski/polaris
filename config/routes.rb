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
  resources :reservations, only: [] do
    resource :payment, only: :create # POST /reservations/:reservation_id/payment
  end

  # Публичный webhook bePaid (Basic Auth + Content-Signature)
  post "bepaid/webhook", to: "bepaid_webhooks#create", as: :bepaid_webhook

  namespace :admin do
    root "dashboard#show"
    get "schedule", to: "schedule#show", as: :schedule
    get "reports/room_hours", to: "reports#room_hours", as: :room_hours_report
    resources :reservations, only: :index do
      member do
        post :confirm
        post :decline
        post :cancel
        post :complete
        post :extend
        post :record_on_site
      end
    end
    resources :zones, except: :show
    resources :amenities, only: %i[index create edit update destroy]
    resources :users, only: %i[index update]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
