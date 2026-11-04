Rails.application.routes.draw do
  # Лендинг на корне; полный каталог — на /zones
  root "zones#landing"
  get "zones", to: "zones#index"

  # Восстановление пароля — только по токену из письма (публичных ссылок нет)
  resources :passwords, param: :token

  # Переключатель темы: «атлас» (светлая) / «ночное небо» (v1)
  resource :theme_switch, only: :create

  # Клиенты бронируют без аккаунта (имя + телефон); персонал входит по спец-ссылке /admin/session.
  # Просмотр и управление бронями — только в админке, публичного раздела броней нет
  resources :zones, only: %i[show] do
    resources :reservations, only: :create
  end

  # Публичный webhook bePaid (Basic Auth + Content-Signature)
  post "bepaid/webhook", to: "bepaid_webhooks#create", as: :bepaid_webhook

  namespace :admin do
    # Спец-ссылка входа для персонала (вручную вводится в браузере)
    resource :session, only: %i[new create destroy]
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
        # Заявка без времени: назначаем слот по телефону с гостем
        post :assign_time
      end
    end
    resources :zones, except: :show
    resources :amenities, only: %i[index create edit update destroy]
    # База клиентов из гостевых броней (телефон обязателен при бронировании)
    resources :clients, only: :index
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
