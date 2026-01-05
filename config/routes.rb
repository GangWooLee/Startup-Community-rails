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

  # Onboarding Flow (AI 분석)
  get "ai/input", to: "onboarding#ai_input", as: :onboarding_ai_input
  post "ai/questions", to: "onboarding#ai_questions", as: :onboarding_ai_questions
  post "ai/analyze", to: "onboarding#ai_analyze", as: :onboarding_ai_analyze
  get "ai/result/:id", to: "onboarding#ai_result", as: :ai_result
  get "ai/expert/:id", to: "onboarding#expert_profile", as: :expert_profile

  # Community (커뮤니티)
  get "community", to: "posts#index", as: :community

  # Authentication
  get    "/login",  to: "sessions#new",     as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout
  get    "/signup", to: "users#new",        as: :signup
  post   "/signup", to: "users#create"

  # Email Verification (회원가입 이메일 인증)
  resources :email_verifications, only: [:create] do
    collection do
      post :verify
    end
  end

  # OAuth Authentication
  # OAuth 요청 전 return_to 저장을 위한 중간 경로
  post "/oauth/:provider", to: "oauth#passthru", as: :oauth_passthru
  match "/auth/:provider/callback", to: "omniauth_callbacks#create", via: [:get, :post]
  get "/auth/failure", to: "omniauth_callbacks#failure"

  # Account Recovery (비밀번호 찾기)
  get   "password/forgot",        to: "account_recovery#forgot_password_form", as: :forgot_password_form
  post  "password/forgot",        to: "account_recovery#forgot_password",      as: :forgot_password
  get   "password/forgot/sent",   to: "account_recovery#forgot_password_sent", as: :forgot_password_sent
  get   "password/reset/:token",  to: "account_recovery#reset_password_form",  as: :reset_password_form
  patch "password/reset/:token",  to: "account_recovery#reset_password",       as: :reset_password

  # Account Deletion (회원 탈퇴) - 즉시 익명화, 복구 불가
  get  "account/delete", to: "user_deletions#new",    as: :delete_account
  post "account/delete", to: "user_deletions#create"

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
  resources :profiles, only: [:show] do
    member do
      post :follow, to: "follows#toggle"  # 팔로우 토글
    end
  end

  # Job Posts (Freelance/Outsourcing) - 외주 마켓플레이스 인덱스
  resources :job_posts, only: [:index]

  # Payments (결제)
  resources :payments, only: [:new, :create] do
    collection do
      get :success
      get :fail
      post :webhook
    end
  end

  # Orders (주문)
  resources :orders, only: [:index, :show] do
    member do
      get :success
      get :receipt
      post :cancel
      post :confirm
    end
  end

  # My Page
  get "my_page", to: "my_page#show", as: :my_page
  get "my_page/edit", to: "my_page#edit", as: :edit_my_page
  get "my_page/idea_analyses", to: "my_page#idea_analyses", as: :my_idea_analyses
  patch "my_page", to: "my_page#update"

  # Settings
  get "settings", to: "settings#show", as: :settings
  patch "settings", to: "settings#update"

  # Reports (신고)
  resources :reports, only: [:create]

  # Inquiries (문의)
  resources :inquiries, only: [:index, :new, :create, :show]

  # shadcn UI Test Page (development only)
  get "shadcn_test", to: "pages#shadcn_test" if Rails.env.development?

  # Legal Pages (법적 페이지)
  get "terms", to: "pages#terms", as: :terms
  get "privacy", to: "pages#privacy", as: :privacy
  get "refund", to: "pages#refund", as: :refund
  get "guidelines", to: "pages#guidelines", as: :guidelines

  # OAuth 약관 동의 (신규 소셜 로그인 사용자용)
  get  "oauth/terms", to: "oauth_terms#show", as: :oauth_terms
  post "oauth/terms/accept", to: "oauth_terms#accept", as: :oauth_terms_accept

  # Search
  get "search", to: "search#index", as: :search
  delete "search/recent", to: "search#destroy_recent", as: :destroy_recent_search
  delete "search/recent/all", to: "search#clear_recent", as: :clear_recent_searches

  # Notifications
  resources :notifications, only: [:index, :show, :destroy] do
    collection do
      get :dropdown
      post :mark_all_read
    end
  end

  # Chat (채팅)
  resources :chat_rooms, only: [ :index, :show, :create, :new ] do
    collection do
      get :search_users
    end
    member do
      post :confirm_deal
      post :cancel_deal
      get :profile_overlay
      delete :leave  # 채팅방 나가기 (소프트 삭제)
    end
    resources :messages, only: [ :create ] do
      collection do
        post :send_profile
        post :send_contact
        post :send_offer
      end
    end
  end

  # 프로필에서 채팅 시작
  post "profiles/:id/start_chat", to: "chat_rooms#create", as: :start_chat

  # 게시글에서 채팅 시작 (컨텍스트 포함)
  post "posts/:id/start_chat", to: "chat_rooms#create_from_post", as: :start_chat_from_post

  # Admin (관리자)
  namespace :admin do
    root to: "dashboard#index"

    resources :users, only: [:index, :show] do
      member do
        get :chat_rooms  # 해당 사용자의 채팅방 목록
      end
    end

    resources :chat_rooms, only: [:show]  # 채팅방 대화 내용 열람

    resources :user_deletions, only: [:index, :show] do
      member do
        post :reveal  # 암호화된 개인정보 열람 (로깅 필수)
      end
    end

    resources :reports, only: [:index, :show, :update]
    resources :inquiries, only: [:index, :show, :update]

    # AI 분석 사용량 관리
    resources :ai_usages, only: [:index, :show] do
      member do
        patch :update_limit           # limit 수정
        patch :update_bonus           # 보너스 크레딧 수정
        patch :set_remaining          # 잔여횟수 직접 설정
        delete :reset                 # 전체 삭제
        delete :destroy_selected      # 선택 삭제
      end
    end
    # 개별 분석 삭제
    delete "ai_usages/:id/analyses/:analysis_id",
           to: "ai_usages#destroy_analysis",
           as: :destroy_ai_analysis
  end
end
