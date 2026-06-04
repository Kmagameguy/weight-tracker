# frozen_string_literal: true

module DayHelper
  def last_weigh_in(day_presenter)
    content_tag(:p, "Most recent weigh-in: #{weight_text(day_presenter.last_weight_entry) }")
  end

  def weight_text(weight_entry)
    if weight_entry
      "#{weight_entry.weight} lbs - #{weight_entry.date.strftime("%B %-d") }"
    else
      "No weigh-ins yet."
    end
  end
end
