module Api
  module V1
    class BaseController < ActionController::API
      wrap_parameters false

      before_action :no_store
      before_action :authenticate_token!

      private

      attr_reader :current_user, :api_token

      def no_store
        response.set_header("Cache-Control", "no-store")
        response.set_header("Pragma", "no-cache")
      end

      def authenticate_token!
        scheme, raw = request.authorization.to_s.split(" ", 2)

        unless scheme == "Bearer" && raw.present? && raw.match(/\A[A-Za-z0-9_-]+\z/)
          return unauthorized!
        end

        record  = ApiToken.authenticate(raw)
        return unauthorized! unless record

        record.touch_last_used!
        @api_token    = record
        @current_user = record.user
      end

      def unauthorized!
        render json: { error: "unauthorized" }, status: :unauthorized
      end
    end
  end
end
