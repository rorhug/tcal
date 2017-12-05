class AdminController < ApplicationController
  before_action :must_be_admin!

  def uninvited
    @cols = %w(google_name)
    @users = User.uninvited
    @user_count = @users.count
  end

  def search_users
    query = params[:q].to_s.strip.downcase

    user_found_by_id = if query =~ /\A\d+\z/
      User.find_by_id(query.to_i)
    end

    results = if query.empty?
      []
    else
      sanitized = query.gsub(/[^\w -]/, "")
      words = sanitized.gsub(" ", "|")

      User.where(
        "LOWER(((auth_hash -> 'info') -> 'name')::text) LIKE ?", "%#{sanitized}%"
      ).or(User.where(
        "email LIKE ?", "%#{sanitized}%"
      )).order(updated_at: :desc).limit(8).to_a

      # User.where(
      #   "LOWER(((auth_hash -> 'info') -> 'name')::text) SIMILAR TO ?", "%(#{keywords})%"
      # ).or(User.where(
      #   "email SIMILAR TO ?", "%(#{keywords})%"
      # )).order(updated_at: :desc).limit(8).to_a
    end

    render json: { users: ([user_found_by_id] + results).compact.map(&:for_front_end) }
  end

  def set_global_setting
    GlobalSetting.set(params[:identifier], params[:value], current_user)
    redirect_to root_path
  end

  private
    def must_be_admin!
      unless current_user.is_admin?
        raise_not_found
      end
    end
end
