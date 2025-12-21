Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root path - Onboarding Landing (메인 진입점)
  # 첫 접속 시 온보딩 화면으로 시작
  root "onboarding#landing"

  # Onboarding Flow
  get "ai/input", to: "onboarding#ai_input", as: :onboarding_ai_input
  get "ai/result", to: "onboarding#ai_result", as: :onboarding_ai_result

  # Community (커뮤니티)
  get "community", to: "posts#index", as: :community

  # Authentication
  get    "/login",  to: "sessions#new",     as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout
  get    "/signup", to: "users#new",        as: :signup
  post   "/signup", to: "users#create"

  # OAuth Authentication
  # OAuth 요청 전 return_to 저장을 위한 중간 경로
  post "/oauth/:provider", to: "oauth#passthru", as: :oauth_passthru
  match "/auth/:provider/callback", to: "omniauth_callbacks#create", via: [:get, :post]
  get "/auth/failure", to: "omniauth_callbacks#failure"

  # Posts (Community)
  resources :posts, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    member do
      post :like, to: "likes#toggle"
      post :bookmark, to: "bookmarks#toggle"
      delete :remove_image
    end
    resources :comments, only: [:create, :destroy] do
      member do
        post :like
      end
    end
  end

  # Profiles
  resources :profiles, only: [:show]

  # Job Posts (Freelance/Outsourcing) - 외주 마켓플레이스 인덱스
  resources :job_posts, only: [:index]

  # My Page
  get "my_page", to: "my_page#show", as: :my_page
  get "my_page/edit", to: "my_page#edit", as: :edit_my_page
  patch "my_page", to: "my_page#update"

  # Settings
  get "settings", to: "settings#show", as: :settings
end
