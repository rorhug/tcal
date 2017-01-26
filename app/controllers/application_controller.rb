class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception unless Rails.env.development?
  helper_method :current_user, :user_setup_complete?

  before_action :authenticate!,
    :ensure_is_tcd_email!,
    :ensure_is_joined!,
    :ensure_my_tcd_login_success!

  prepend_before_action :set_raven_context

  def current_user
    return @current_user if defined?(@current_user)
    return unless session[:user_id]
    @current_user = User.find_by_id(session[:user_id])
  end

  def user_setup_complete?
    current_user && current_user.my_tcd_login_success?
  end

  def raise_not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  private
    def authenticate!
      if session[:user_id] && current_user
        if current_user.set_joined_at_if_invited!
          flash[:success] = "#{current_user.you_were_invited_message}, Welcome!"
        end
        nil # method returns nil if user
      else
        reset_session
        redirect_to root_path # method returns a redirect if no user
      end
    end

    def ensure_is_tcd_email!
      if current_user && !current_user.tcd_email?
        flash[:error] = "This service is only available to tcd.ie Google Accounts"
        unless params >= { "controller" => "users", "action" => "setup", "step" => "google" }
          redirect_to setup_step_path(step: "google")
        end
      end
    end

    def ensure_is_joined!
      if current_user && !current_user.joined_at?
        redirect_to invite_needed_invites_path
      end
    end

    def ensure_my_tcd_login_success!
      if current_user && !current_user.my_tcd_login_success?
        redirect_to setup_step_path(step: "my_tcd")
      end
    end

    def set_raven_context
      Raven.user_context(current_user.for_raven) if current_user
      Raven.extra_context(params: params.to_unsafe_h, url: request.url)
    end
end
