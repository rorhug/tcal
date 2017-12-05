class UsersController < ApplicationController
  # SETUP_STEPS = %w(my_tcd google)

  before_action :load_user
  skip_before_action :ensure_my_tcd_login_success!, only: [:sync_status]

  def update_sync_settings
    @user.update_attributes!(params.require(:user).permit(:auto_sync_enabled))
    redirect_to setup_step_path(step: "customise")
  end

  def manual_sync
    block_reason = @user.sync_blocked_reason
    if block_reason
      flash[:error] = block_reason
    else
      @user.enqueue_sync
    end
    redirect_to @user == current_user ? root_path : admin_user_path(@user)
  end

  def sync_status
    unless @user.my_tcd_login_success?
      return render json: {}
    end
    que_job = @user.get_ongoing_sync_job
    render json: { run_at: que_job && view_context.time_ago_in_words(que_job.run_at) }
  end

  def upcoming_events
    @events_by_date = @user.gcs.fetch_upcoming_events_for_feed
    render partial: "users/upcoming_events"
  end

  private

  def load_user
    @user ||= if params[:id] == "me"
      @user_id_to_link = "me"
      current_user
    else
      if current_user.is_admin?
        user = User.find(params[:id])
        @user_id_to_link = user.id
        user
      else
        raise_not_found
      end
    end
  end
end
