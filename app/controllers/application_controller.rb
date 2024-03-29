class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception unless Rails.env.development?
  helper_method :current_user, :user_setup_complete?, :login_available?

  before_action :authenticate!,
    :ensure_email_is_allowed!,
    :ensure_is_joined!,
    :ensure_my_tcd_login_success!,
    :update_last_user_agent!

  prepend_before_action :set_raven_context

  def current_user
    return @current_user if defined?(@current_user)
    return unless session[:user_id]
    @current_user = User.find_by_id(session[:user_id])
    Rails.logger.info("  current_user id=#{@current_user.try(:id)} email=#{@current_user.try(:email)}")
    @current_user
  end

  def login_available?
    return @_login_available if defined?(@_login_available)
    # @login_available = params[:revive].present? || GlobalSetting.get("login_enabled").value
    # TODO make custom links, hash(salt + id) of invited user
    @_login_available = !accessed_from_tcd_network? && (GlobalSetting.get("login_enabled").value)# || valid_id_token_present?)
  end

  def user_setup_complete?
    current_user && current_user.my_tcd_login_success?
  end

  def raise_not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  private
    def authenticate!
      if session[:user_id] && current_user && login_available?
        if current_user.set_joined_at_if_invited!
          flash[:success] = "#{current_user.you_were_invited_message}, Welcome!"
        end
        nil # method returns nil if user, i.e. no redirect
      else
        reset_session
        redirect_to root_path # method returns a redirect if no user
      end
    end

    def ensure_email_is_allowed!
      return unless current_user

      if !current_user.tcd_email? || current_user.blocked_as_staff_member?
        # flash[:error] = "This service is only available to tcd.ie Google Accounts"
        redirect_to user_not_compatible_path
      end
    end

    def ensure_is_joined!
      return unless current_user

      unless current_user.joined_at?
        redirect_to invite_needed_invites_path
      end
    end

    def ensure_my_tcd_login_success!
      return unless current_user

      unless current_user.my_tcd_login_success?
        redirect_to setup_step_path(step: "my_tcd")
      end
    end

    def set_raven_context
      Raven.user_context(current_user.for_raven) if current_user
      Raven.extra_context(params: params.to_unsafe_h, url: request.url)
    end

    def update_last_user_agent!
      if current_user && request.user_agent.is_a?(String)
        current_user.update_attributes!(last_user_agent: request.user_agent[0..500])
      end
    end

    def accessed_from_tcd_network?
      request.remote_ip.start_with?("134.226")
      # request.remote_ip.start_with?("127")
    end
end
