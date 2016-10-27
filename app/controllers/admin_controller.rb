class AdminController < ApplicationController
  before_action :must_be_admin!

  def uninvited
    @cols = %w(google_name)
    @users = User.uninvited
    @user_count = @users.count
  end

  private
    def must_be_admin!
      unless current_user.is_admin?
        raise ActionController::RoutingError.new('Not Found')
      end
    end
end
