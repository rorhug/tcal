class SessionsController < ApplicationController
  skip_before_action :authenticate!, only: [:new, :create, :destroy]
  skip_before_action :ensure_is_tcd_email!,
                     :ensure_is_joined!,
                     :ensure_my_tcd_login_success!,
                     only: [:destroy, :failure]

  def create
    user = User.from_omniauth(auth_hash)
    # MAYBE get refresh on login if not there, probably unecessary
    # if user.oauth_refresh_token.blank?
    #   return redirect_to("/auth/google_oauth2?prompt=consent")
    # end
    session[:user_id] = user.id
    redirect_to user_setup_complete? ? root_path : user_setup_step_path(step: "my_tcd")
  rescue SecurityError
    reset_session
    render :text => '401 Unauthorized', :status => 401
  end

  def destroy
    reset_session
    redirect_to root_path
  end

  def failure
    flash[:error] = "Authorization failure!"
    redirect_to root_path
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
