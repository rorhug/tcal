Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "users#index"

  scope "/auth" do
    get "/google_oauth2/callback", to: "sessions#create"
    get "/failure", to: "sessions#failure"
    delete "/", to: "sessions#destroy", as: :logout_user
  end

  resource :user, only: [:update] do
    get "/setup/:step", action: :setup, as: :setup
  end
end
