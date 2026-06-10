class ApplicationController < ActionController::Base
  around_action :use_user_timezone
  helper_method :day_path_for

  include Authentication
  include RoutingHelper
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def use_user_timezone(&block)
    zone = Current.user&.timezone.presence || Rails.application.config.time_zone
    Time.use_zone(zone, &block)
  end

  def redirect_if_authenticated
    redirect_to root_path if authenticated?
  end
end
