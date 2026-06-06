module RoutingHelper
  def day_path_for(object)
    date = object.respond_to?(:date) ? object.date : object

    day_path(date.year, date.month, date.day)
  end
end
