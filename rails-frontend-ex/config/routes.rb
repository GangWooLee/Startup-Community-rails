Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Root path - Community page
  root "community#index"

  # Community routes
  resources :community, only: [:index, :show, :new, :create]

  # Profile routes
  get 'profile/:id', to: 'profiles#show', as: :profile

  # Freelance routes
  resources :freelance, only: [:index] do
    collection do
      get 'new'
    end
  end
  get 'freelance/job/:id', to: 'freelance#show_job', as: :freelance_job
  get 'freelance/talent/:id', to: 'freelance#show_talent', as: :freelance_talent

  # My Page routes
  get 'my-page', to: 'my_page#show', as: :my_page
  get 'my-page/edit', to: 'my_page#edit', as: :edit_my_page
  patch 'my-page', to: 'my_page#update'
end
