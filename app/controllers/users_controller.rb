class UsersController < ApplicationController
  # SETUP_STEPS = %w(my_tcd google)

  skip_before_action :ensure_my_tcd_login_success!, only: [:setup, :update_my_tcd_details, :tcd_only]
  skip_before_action :ensure_is_tcd_email!, only: [:setup, :tcd_only]

  def setup
    @step = params[:step]

    case @step
    when "google"
      # google step
    when "my_tcd"
      if current_user.my_tcd_login_success == false # Only if SET to false
        flash[:error] ||= "Your MyTCD details didn't work last time, try re-entering them to continue."
      end
    when nil
      # setup home
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def tcd_only
    redirect_to root_path if current_user.tcd_email?
  end

  def update_sync_settings
    current_user.update_attributes!(params.require(:user).permit(:auto_sync_enabled))
    redirect_to root_path
  end

  def update_my_tcd_details
    @step = "my_tcd"

    is_updated = current_user.update_attributes(
      params.require(:user).permit(:my_tcd_username, :my_tcd_password)
    )

    if User::MY_TCD_LOGIN_COLUMNS.select { |attr| current_user.send(attr).blank? }.any?
      flash[:error] = "Please provide a username and password"
      return render :setup
    end

    if is_updated
      begin
        MyTcd::TimetableScraper.new(current_user).test_login_success!

        current_user.enqueue_sync unless current_user.sync_blocked_reason
        flash[:success] = "Connection to MyTCD successful!"
        redirect_to root_path
      rescue MyTcd::MyTcdError => e
        flash[:error] = e.message
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
end
