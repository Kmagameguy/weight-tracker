class ApiTokensController < ApplicationController
  def destroy
    Current.user.api_tokens.find(params[:id]).destroy!
    redirect_to profile_path, notice: "Device signed out.", status: :see_other
  end

  def destroy_all
    Current.user.api_tokens.destroy_all
    redirect_to profile_path, notice: "All devices signed out.", status: :see_other
  end
end
