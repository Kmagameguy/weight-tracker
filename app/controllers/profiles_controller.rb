class ProfilesController < ApplicationController
  before_action :set_user, only: %i[show update]

  def show; end

  def update
    if @user.update(user_params)
      flash[:notice] = "Profile updated successfully."
      redirect_to profile_path
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def user_params
    params.expect(user: [ :daily_calorie_goal, :timezone ])
  end
end
