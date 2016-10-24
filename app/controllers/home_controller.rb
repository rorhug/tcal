class HomeController < ApplicationController
  skip_before_action :authenticate!, only: :index

  def index
    current_user ? user_index : landing_index
  end

  def upcoming_events
    @events_by_date = GoogleCalendarSync.new(current_user).fetch_upcoming_events_for_feed
    render partial: "upcoming_events"
  end

  private
    def user_index
      @que_job = current_user.ongoing_sync_job
      @attempts = current_user.sync_attempts.for_feed.to_a
      @sync_block_reason = current_user.sync_blocked_reason

      @invitees = ([User.new] * current_user.invites_left) + current_user.invitees.first(10)
      render "user_index"
    end

    def landing_index
      if params[:invitee_email]
        @invitee = User.find_by_email(params[:invitee_email])
        if @invitee
          if @invitee.joined_at?
            flash[:success] = "Your account is already setup, login to continue."
            flash[:error] = nil
          elsif @invitee.invited_by
            flash[:success] = "#{@invitee.invited_by.email} invited you to use Tcal. Press Login to get started!"
            flash[:error] = nil
          else
            flash[:error] = "Haha, nice try :)"
            flash[:success] = nil
          end
        else
          flash[:error] = "Invalid invite link :/"
          flash[:success] = nil
        end
      end
      render "landing_index"
    end
end
