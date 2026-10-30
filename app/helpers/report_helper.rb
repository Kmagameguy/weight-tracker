module ReportHelper
  def report_date(date)
    date.strftime("%b %-d, %Y")
  end

  def report_short_date(date)
    date.strftime("%b %-d")
  end

  def signed_weight(value)
    prefix = value.positive? ? "+" : ""
    "#{prefix}#{number_with_precision(value, precision: 1)}"
  end
end
