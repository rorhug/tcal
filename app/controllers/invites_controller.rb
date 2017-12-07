class InvitesController < ApplicationController
  skip_before_action :ensure_is_joined!, only: [:invite_needed]
  skip_before_action :ensure_my_tcd_login_success!, only: [:invite_needed]

  def create
    path_for_redirect = if current_user.is_admin? && params[:admin_redirect_path]
      params[:admin_redirect_path]
    else
      root_path
    end

    flash[:error] = "Invites disabled..."
    return redirect_to path_for_redirect

    # BELOW UNUSED ATM

    # No more invites
    unless current_user.has_spare_invites?
      flash[:error] = "You've already used up your #{User::MAX_INVITES} invites"
      flash[:invites_error] = true
      return redirect_to path_for_redirect
    end


    invite_email_to_use = user_params[:email].strip.downcase
    user_to_invite = current_user.invitees.new(email: invite_email_to_use)

    # Only tcd.ie emails
    unless user_to_invite.tcd_email?
      flash[:error] = "You may only invite tcd.ie emails!"
      flash[:invites_error] = true
      return redirect_to path_for_redirect
    end

    # User exists
    existing_user = User.find_by_email(user_to_invite.email)
    if existing_user
      if existing_user.joined_at? # and is an active user...
        flash[:error] = "#{existing_user.email} already uses Tcal"
      elsif existing_user.invited_by_user_id # or has already been invited
        flash[:error] = "#{existing_user.invited_by_user_id == current_user.id ? "You've" : "Someone else has"} already invited #{existing_user.email}"
      else # has an account, but is stuck at invite wall isn't joined yet
        existing_user.invited_by = current_user
        existing_user.save!
        existing_user.enqueue_invite_email
        flash[:success] = "#{existing_user.email} can now sign in!"
      end
      flash[:invites_error] = true if flash[:error]
      return redirect_to path_for_redirect # for if and else ^
    end

    user_to_invite.save!
    user_to_invite.enqueue_invite_email
    flash[:success] = "Tell #{user_to_invite.email} to check their inbox!"

    return redirect_to path_for_redirect
  end

  def invite_needed
    redirect_to root_path if current_user.joined_at? && !current_user.is_admin?
  end

  private

    def user_params
      params.require(:user).permit(:email)
    end
end
