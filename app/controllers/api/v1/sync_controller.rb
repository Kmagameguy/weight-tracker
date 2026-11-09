module Api
  module V1
    class SyncController < BaseController
      SETTINGS = %i[
        daily_calorie_goal
        timezone
        calorie_tracking_enabled
        weight_tracking_enabled
        blood_pressure_tracking_enabled
        journaling_enabled
        tagging_enabled
      ].freeze

      def create
        body    = sync_params
        changes = body.fetch(:changes, []).map(&:to_h)
        result  = SyncService.new(user: current_user, cursor: body[:cursor], changes: changes).call

        render json: result.merge(user: current_user.slice(*SETTINGS))
      rescue ArgumentError
        render json: { error: "invalid cursor" }, status: :unprocessable_entity
      end

      private

      def sync_params
        params.permit(
          :cursor,
          changes: %i[
            type
            op
            uuid
            client_updated_at
            tag_uuid
            name
            calories
            date
            weight
            systolic
            diastolic
            note
          ]
        )
      end
    end
  end
end
