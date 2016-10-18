class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception unless Rails.env.development?
  helper_method :current_user, :user_ready_to_sync?
  before_action :authenticate!

  def current_user
    return unless session[:user_id]
    @current_user ||= User.find_by_id(session[:user_id])
  end

  def user_ready_to_sync?
    current_user && current_user.my_tcd_login_success?
  end

  private
    def authenticate!
      unless session[:user_id] && current_user
        reset_session
        redirect_to setup_user_path(step: "google")
      end
    end

end
