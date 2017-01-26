class Admin::UsersController < ApplicationController
  before_action :must_be_admin!
  before_action :load_user, only: [:show]

  def index
    @cols = %w(google_name)
    @users = User.uninvited
    @user_count = @users.count
  end

  def search
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

  def show
    @que_job = @user.ongoing_sync_job
    @attempts = @user.sync_attempts.for_feed.to_a
    @sync_block_reason = @user.sync_blocked_reason
  end

  private
    def must_be_admin!
      unless current_user.is_admin?
        raise ActionController::RoutingError.new('Not Found')
      end
    end

    def load_user
      @user ||= User.find(params[:id])
      @user_id_to_link = @user.id
    end
end
