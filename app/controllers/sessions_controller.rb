class SessionsController < ApplicationController
  before_action :redirect_authenticated_user, only: %i[new create]

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "Welcome back, #{user.username}!"
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "You have been logged out."
  end

  private

  def redirect_authenticated_user
    redirect_to root_path if current_user
  end
end
