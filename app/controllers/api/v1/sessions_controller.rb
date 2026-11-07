module Api
  module V1
    class SessionsController < ActionController::API
      rate_limit to: 10, within: 3.minutes, only: :create,
                 with: -> { render json: { error: "Try again later" }, status: :too_many_requests }

      def create
        user = authenticate_user
        return render(json: { error: "invalid credentials" }, status: :unauthorized) unless user

        token = ApiToken.issue_for(user, name: params[:device_name].to_s.first(100))
        render json: { token: token }, status: :created
      end

      private

      def authenticate_user
        return if params[:email_address].blank? || params[:password].blank?

        User.authenticate_by(email_address: params[:email_address], password: params[:password])
      end
    end
  end
end
