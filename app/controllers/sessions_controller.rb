class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email].downcase)
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:notice] = "You've successfully logged in."
      redirect_to root_path
    else
      flash[:alert] = "Unable to login"
      redirect_to login_path
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Logged out", status: :see_other
  end
end
