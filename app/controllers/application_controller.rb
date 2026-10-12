class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :current_user

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def require_login
    return if current_user

    redirect_to login_path, alert: "Please log in to continue."
  end
end
