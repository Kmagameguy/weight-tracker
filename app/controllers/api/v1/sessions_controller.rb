module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_token!, only: :create

      RATE_LIMITED = -> { render json: { error: "try again later" }, status: :too_many_requests }

      rate_limit to: 10, within: 3.minutes, only: :create, name: "login-ip", with: RATE_LIMITED
      rate_limit to: 10, within: 15.minutes, only: :create, name: "login-account",
                 by: -> { params[:email_address].to_s.strip.downcase }, with: RATE_LIMITED

      def create
        user = authenticate_user
        return render(json: { error: "invalid credentials" }, status: :unauthorized) unless user

        token = ApiToken.issue_for(user, name: device_name)
        render json: { token: token }, status: :created
      end

      def destroy
        api_token.destroy!
        head :no_content
      end

      private

      def device_name
        params[:device_name].to_s.squish.first(100).presence || "Unknown device"
      end

      def authenticate_user
        email_address = params[:email_address].to_s.strip.downcase
        password = params[:password]

        return if email_address.blank? || password.blank?

        User.authenticate_by(email_address: email_address, password: password)
      end
    end
  end
end
