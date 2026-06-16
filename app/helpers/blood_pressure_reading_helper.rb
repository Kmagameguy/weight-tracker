module BloodPressureReadingHelper
  def blood_pressure_label_color(blood_pressure_reading)
    case blood_pressure_reading.category
    when BloodPressureReading::STAGE_TWO_HYPERTENSION
      "text-red-500"
    when BloodPressureReading::STAGE_ONE_HYPERTENSION
      "text-orange-500"
    when BloodPressureReading::ELEVATED_BLOOD_PRESSURE
      "text-yellow-500"
    else
      "text-emerald-500"
    end
  end
end
