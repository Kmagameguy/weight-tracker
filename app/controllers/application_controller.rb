class ApplicationController < ActionController::Base
  helper_method :day_path_for

  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def day_path_for(object)
    date = object.respond_to?(:date) ? object.date : object

    day_path(date.year, date.month, date.day)
  end
end
