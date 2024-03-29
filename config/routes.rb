Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "home#index"

  get "/about" => "home#about"
  get :user_not_compatible, controller: :home

  resource :home, controller: :home, only: [:index]

  scope "/auth" do
    get "/google_oauth2/callback", to: "sessions#create"
    get "/failure", to: "sessions#failure"
    delete "/", to: "sessions#destroy", as: :logout_user
  end

  scope :setup, as: :setup, controller: :home do
    get "/", action: :setup, as: :index
    get "/:step", action: :setup, as: :step
    match "/my_tcd", action: :update_my_tcd_details, via: [:put, :patch], as: nil
  end

  resources :users, only: [] do
    member do
      post :manual_sync
      match :update_sync_settings, via: [:put, :patch]
      get :sync_status
      get :upcoming_events
    end
  end

  resource :invites, only: [:create] do
    get :invite_needed
    match "/", action: :create, via: [:put, :patch]
  end

  # resource :admin, controller: :admin, only: [] do
  #   get :uninvited
  #   get :search_users
  # end

  namespace :admin do
    resources :users, only: [:show, :index] do
      post :search, on: :collection

      delete :calendar, action: :delete_calendar, on: :member
    end

    post :set_global_setting
  end
end
