module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_token!

      private

      attr_reader :current_user

      def authenticate_token!
        raw     = request.authorization.to_s[/\Bearer (.+)\z/, 1]
        record  = ApiToken.authenticate(raw)
        return render(json: { error: "unauthorized" }, status: :unauthorized) unless record

        record.touch(:last_used_at)
        @current_user = record.user
      end
    end
  end
end
