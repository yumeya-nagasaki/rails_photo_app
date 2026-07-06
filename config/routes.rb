Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resources :photos, only: [ :index, :new, :create ] do
    member do
      post :tweet
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "oauth/authorize", to: "oauth#authorize", as: :oauth_authorize
  get "oauth/callback", to: "oauth#callback", as: :oauth_callback

  # Defines the root path route ("/")
  # 写真一覧画面へ（ログインしていない場合はログイン画面へ）
  root "photos#index"
end
