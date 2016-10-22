class SessionsController < ApplicationController
  skip_before_action :authenticate!, only: [:new, :create]

  def create
    user = User.from_omniauth(auth_hash)
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
    flash[:error] = "Auth fail!"
    redirect_to :new
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
