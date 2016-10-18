class UsersController < ApplicationController
  SETUP_STEPS = %w(my_tcd google)

  before_action :ensure_setup, except: [:setup, :update]
  skip_before_action :authenticate!, only: [:setup]

  def setup
    @step = params[:step]
    raise ActionController::RoutingError.new('Not Found') if SETUP_STEPS.exclude?(@step)
    redirect_to setup_user_path(step: "google") if @step == "my_tcd" && !current_user
  end

  def index
  end

  def update
    @step = "my_tcd"
    is_updated = current_user.update_attributes(user_params)
    if is_updated
      begin
        MyTcd::TimetableScraper.new(current_user).test_login_success!
        flash[:success] = "Connection to my.tcd.ie successful!"
        redirect_to root_path
      rescue MyTcd::MyTcdError => e
        flash[:error] = e.message || "Unknown MyTcd login error :("
        render :setup
      end
    else
      flash[:error] = "Error saving user details!"
      render :setup
    end
  end

  private

  def user_params
    params.require(:user).permit(:my_tcd_username, :my_tcd_password)
  end

  def ensure_setup
    redirect_to setup_user_path(step: "my_tcd") unless user_ready_to_sync?
  end
end
