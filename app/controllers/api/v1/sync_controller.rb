module Api
  module V1
    class SyncController < BaseController
      MAX_BODY_SIZE = 2.megabytes

      SETTINGS = %i[
        daily_calorie_goal
        timezone
        calorie_tracking_enabled
        weight_tracking_enabled
        blood_pressure_tracking_enabled
        journaling_enabled
        tagging_enabled
      ].freeze

      before_action :limit_body_size

      rescue_from SyncService::InvalidRequest do |error|
        render json: { error: "invalid_request", detail: error.message }, status: :unprocessable_entity
      end

      rescue_from SyncService::TooManyChanges do |error|
        render json: { error: "too_many_changes", detail: error.message }, status: :content_too_large
      end

      rescue_from SyncService::InvalidCursor do |error|
        render json: { error: "cursor_reset", detail: error.message }, status: :conflict
      end

      def create
        body = request.request_parameters
        result = SyncService.new(user: current_user, cursor: body["cursor"], changes: body["changes"]).call

        render json: result.merge(user: current_user.slice(*SETTINGS))
      end

      private

      def limit_body_size
        return if request.content_length.to_i <= MAX_BODY_SIZE

        render json: { error: "too_large" }, status: :content_too_large
      end
    end
  end
end
