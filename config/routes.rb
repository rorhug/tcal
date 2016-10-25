Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "home#index"

  resource :home, controller: :home, only: [:index] do
    get :upcoming_events
  end

  scope "/auth" do
    get "/google_oauth2/callback", to: "sessions#create"
    get "/failure", to: "sessions#failure"
    delete "/", to: "sessions#destroy", as: :logout_user
  end

  resource :user, only: [] do
    get "/" => redirect("/")

    nested do
      scope :setup, as: :setup do
        get "/", action: :setup, as: :index
        get "/:step", action: :setup, as: :step
        match "/my_tcd", action: :update_my_tcd_details, via: [:put, :patch], as: nil
      end
    end

    post :manual_sync
    match :update_sync_settings, via: [:put, :patch]
    get :sync_status
  end

  resource :invites, only: [:create] do
    get :invite_needed
    match "/", action: :create, via: [:put, :patch]
  end

  resource :admin, controller: :admin, only: [] do
    get :uninvited
  end
end
