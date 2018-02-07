class HomeController < ApplicationController
  skip_before_action :authenticate!, only: [:index, :about]
  skip_before_action :ensure_my_tcd_login_success!, only: [:setup, :update_my_tcd_details, :about, :user_not_compatible]
  skip_before_action :ensure_email_is_allowed!, only: [:user_not_compatible]
  skip_before_action :ensure_is_joined!, only: [:user_not_compatible]

  before_action :load_user, only: [:setup]

  def index
    if current_user
      return if authenticate!
      load_user
      user_index
    else
      landing_index
    end
  end

  def about
  end

  def summer_landing_page
    render 'summer_landing_page/index.html', layout: false
  end

  def setup
    @step = params[:step]

    case @step
    when "google"
      # google step
    when "my_tcd"
      @user.my_tcd_username = @user.my_tcd_username_estimate if @user.my_tcd_username.blank?
      # if @user.my_tcd_login_success == false # Only if SET to false
      #   flash[:error] ||= "Your MyTCD details didn't work last time, try re-entering them to continue."
      # end
    when "customise"
      # customise
    when nil
      # setup home
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def update_my_tcd_details
    @step = "my_tcd"

    current_user.assign_attributes(
      params.require(:user).permit(:my_tcd_username, :my_tcd_password)
    )

    if User::MY_TCD_LOGIN_COLUMNS.select { |attr| current_user.send(attr).blank? }.any?
      flash[:error] = "Please provide a username and password"
      return render :setup
    end

    if current_user.save
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

  def user_not_compatible
    if current_user.tcd_email? && !current_user.blocked_as_staff_member?
      return redirect_to root_path
    end
    @staff = current_user.matching_staff_members.first
  end

  private
    def user_index
      @que_job = current_user.get_ongoing_sync_job
      @attempts = current_user.sync_attempts.for_feed.to_a
      @sync_block_reason = current_user.sync_blocked_reason(job: @que_job)

      @invitees = ([User.new] * current_user.invites_left) + current_user.invitees.order(id: :desc).limit(10)
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
            flash[:success] = "#{@invitee.you_were_invited_message}. Press Login to get started!"
            flash[:error] = nil
          else
            flash[:error] = "Haha, nice try :) Please wait until you receive an invite email!"
            flash[:success] = nil
          end
        else
          flash[:error] = "Invalid invite link :/"
          flash[:success] = nil
        end
      end

      render "landing_index"
    end

    def load_user
      @user = current_user
      @user_id_to_link = "me"
    end
end
