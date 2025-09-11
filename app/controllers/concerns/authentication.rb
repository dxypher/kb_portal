module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?, :current_team
  end

  def current_user
    return @current_user if defined?(@current_user)
    uid = session[:user_id]
    @current_user = uid ? User.find_by(id: uid) : nil
  end

  def current_team
    @current_team ||= current_user&.teams&.first
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?
    flash[:alert] = "Please login to continue."
    redirect_to login_path, status: :see_other
  end
end
