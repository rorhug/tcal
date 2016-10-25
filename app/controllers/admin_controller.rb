class AdminController < ApplicationController
  before_action :must_be_admin!

  def uninvited
    @cols = %w(name)
    @users = User.uninvited.order(id: :asc)
  end

  private
    def must_be_admin!
      unless current_user.is_admin?
        raise ActionController::RoutingError.new('Not Found')
      end
    end
end
