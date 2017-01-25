class AdminController < ApplicationController
  before_action :must_be_admin!

  def uninvited
    @cols = %w(google_name)
    @users = User.uninvited
    @user_count = @users.count
  end

  # ===== SEARCH QUERY =====
  # SELECT
  #   (auth_hash -> 'info') -> 'name' AS name,
  #   *
  # FROM users
  # WHERE
  #   LOWER(((auth_hash -> 'info') -> 'name')::text) LIKE '%maher patrick%' -- change
  #   OR
  #   email LIKE '%patrick%'
  #   OR
  # --  id=NULLIF('a', '')::int
  #   'patrick' = cast(id as text)
  # ORDER BY id DESC;

  def search_users
    query = params[:q].to_s.strip.downcase

    relation = if query.empty?
      []
    elsif query =~ /\A\d+\z/
      [User.find_by_id(query.to_i)]
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

    render json: { users: relation.compact.map(&:for_raven) }
  end

  private
    def must_be_admin!
      unless current_user.is_admin?
        raise ActionController::RoutingError.new('Not Found')
      end
    end
end
