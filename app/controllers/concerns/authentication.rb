module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?
  end

  def current_user
    return @current_user if defined?(@current_user)
    uid = session[:user_id]
    @current_user = uid ? User.find(session[:user_id]) : nil
  end

  def logged_in?
    @current_user.present?
  end

  def require_login
    nil if logged_in?
    flash[:alert] = "Please login to continue."
    redirect_to login_path
  end
end
