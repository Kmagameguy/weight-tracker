module ProfileHelper
  def number_to_sequence(number)
    return "" if number.blank? || !number.respond_to?(:to_i)

    case number.to_i
    when 1
      "once"
    when 2
      "twice"
    else
      "#{number.to_i} times"
    end
  end

  def avg_daily_calories_label(avg_daily_calories)
    return blank_entry if avg_daily_calories.blank?

    content_tag(:p, class: "text-2xl font-medium text-slate-900") do
      concat number_with_delimiter(avg_daily_calories)
      concat "  "
      concat content_tag(:span, "kcal", class: "text-xs font-normal text-slate-400")
    end
  end

  def calorie_diff_label(diff)
    return unless diff.present?

    prefix  = diff.positive? ? "+" : ""
    content = "no change"
    content = "#{prefix}#{number_with_delimiter(diff)} vs last week" unless diff.zero?
    content += (" " + "vs last week")


    content_tag(:p, content, class: "text-xs mt-1")
  end

  def weight_change_label(weight_change)
    return blank_entry if weight_change.blank?

    content_tag(:p, class: "text-2xl font-medium text-slate-900") do
      concat weight_change.positive? ? "+#{weight_change}" : weight_change
      concat "  "
      concat content_tag(:span, "lbs", class: "text-xs font-normal text-slate-400")
    end
  end

  def weight_change_diff(weight_change)
    return unless weight_change.present?

    content_tag(:p, class: "text-xs mt-1") do
      compare(weight_change, 0)
    end
  end

  def avg_blood_pressure_label(avg_blood_pressure)
    return blank_entry if avg_blood_pressure.blank?

    content_tag(:p, class: "text-2xl font-medium text-slate-900") do
      concat avg_blood_pressure.combined_value
      concat "  "
      concat content_tag(:span, "mmHg", class: "text-xs font-normal text-slate-400")
    end
  end

  def blood_pressure_diff(current_avg_bp, previous_avg_bp)
    return unless current_avg_bp.present? && previous_avg_bp.present?

    content_tag(:p, class: "text-xs mt-1") do
      compare(current_avg_bp, previous_avg_bp)
    end
  end

  def compare(item1, item2)
    case item1 <=> item2
    when -1 then "↓ trending down"
    when 0  then "no change"
    when 1  then "↑ trending up"
    end
  end

  def blank_entry
    content_tag(:p, "—", class: "text-2xl font-medium text-slate-200")
  end
end
