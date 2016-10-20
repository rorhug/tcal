class UsersController < ApplicationController
  SETUP_STEPS = %w(my_tcd google)

  before_action :ensure_setup, except: [:setup, :update]
  skip_before_action :authenticate!, only: [:setup]

  def setup
    @step = params[:step]

    raise ActionController::RoutingError.new('Not Found') if @step.present? && SETUP_STEPS.exclude?(@step)
    return redirect_to setup_user_path(step: "google") unless @step == "google" || current_user

    if @step == "my_tcd" && current_user.my_tcd_login_success == false
      flash[:error] ||= "Your MyTcd details didn't work last time, try re-entering them to continue."
    end
  end

  def index
    @que_job = current_user.ongoing_sync_job
    @attempts = current_user.sync_attempts.for_feed.to_a
    @sync_block_reason = current_user.sync_blocked_reason
  end

  def update
    @step = "my_tcd"
    is_updated = current_user.update_attributes(user_params)
    if is_updated
      begin
        MyTcd::TimetableScraper.new(current_user).test_login_success!
        flash[:success] = "Connection to MyTcd successful!"
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

  def manual_sync
    block_reason = current_user.sync_blocked_reason
    if block_reason
      flash[:error] = block_reason
    else
      current_user.enqueue_sync
    end
    redirect_to root_path
  end

  def sync_status
    que_job = current_user.ongoing_sync_job
    render json: { run_at: que_job && view_context.time_ago_in_words(que_job.run_at) }
  end

  private

  def user_params
    params.require(:user).permit(:my_tcd_username, :my_tcd_password)
  end

  def ensure_setup
    redirect_to setup_user_path(step: "my_tcd") unless user_setup_complete?
  end
end
