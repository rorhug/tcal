class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception unless Rails.env.development?
  helper_method :current_user, :user_setup_complete?

  before_action :authenticate!
  before_action :set_raven_context

  skip_after_action :intercom_rails_auto_include if Rails.env.development?

  def current_user
    return unless session[:user_id]
    @current_user ||= User.find_by_id(session[:user_id])
  end

  def user_setup_complete?
    current_user && current_user.my_tcd_login_success?
  end

  private
    def authenticate!
      unless session[:user_id] && current_user
        reset_session
        redirect_to setup_user_path(step: "google")
      end
    end

    def set_raven_context
      Raven.user_context(current_user.for_raven) if current_user
      Raven.extra_context(params: params.to_unsafe_h, url: request.url)
    end
end
