class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params.merge(daily_calorie_goal: 2_000))
    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "You account has been created."
    else
      flash[:alert] = @user.errors.full_messages.join("\n")
      render :new
    end
  end

  private

  def user_params
    params.expect(user: [ :email_address, :password, :password_confirmation, :daily_calorie_goal ])
  end
end
