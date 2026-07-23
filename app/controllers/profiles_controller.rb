class ProfilesController < ApplicationController
  # Workaround for issues w/the global CSP directives/nonces and
  # chartkick's inline style/scripts applied to each rendered chart.
  content_security_policy only: :show do |policy|
    policy.script_src_elem :self, :unsafe_inline
    policy.style_src_attr  :self, :unsafe_inline
  end

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
    params.expect(user: %i[
      daily_calorie_goal
      timezone
      calorie_tracking_enabled
      weight_tracking_enabled
      blood_pressure_tracking_enabled
    ])
  end
end
