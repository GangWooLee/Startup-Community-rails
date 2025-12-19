Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root path - Community Home
  root "posts#index"

  # Authentication
  get    "/login",  to: "sessions#new",     as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout
  get    "/signup", to: "users#new",        as: :signup
  post   "/signup", to: "users#create"

  # OAuth Authentication
  match "/auth/:provider/callback", to: "omniauth_callbacks#create", via: [:get, :post]
  get "/auth/failure", to: "omniauth_callbacks#failure"

  # Posts (Community)
  resources :posts, only: [:index, :show, :new, :create]

  # Profiles
  resources :profiles, only: [:show]

  # Job Posts (Freelance/Outsourcing)
  resources :job_posts, only: [:index, :show]

  # My Page
  get "my_page", to: "my_page#show", as: :my_page
  get "my_page/edit", to: "my_page#edit", as: :edit_my_page
  patch "my_page", to: "my_page#update"
end
