class BloodPressureReadingsController < ApplicationController
  before_action :set_blood_pressure_reading, only: %i[edit update destroy]

  def create
    @blood_pressure_reading = Current.user.blood_pressure_readings.build(blood_pressure_reading_params)
    if @blood_pressure_reading.save
      redirect_to day_path_for(@blood_pressure_reading)
    else
      redirect_to(
        day_path_for(Date.parse(params[:blood_pressure_reading][:date])),
        alert: @blood_pressure_reading.errors.full_messages.to_sentence
      )
    end
  end

  def edit; end

  def update
    if @blood_pressure_reading.update(blood_pressure_reading_params)
      redirect_to day_path_for(@blood_pressure_reading)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @date = @blood_pressure_reading.date
    @blood_pressure_reading.destroy!

    redirect_to day_path_for(@date)
  end

  private

  def set_blood_pressure_reading
    @blood_pressure_reading = Current.user.blood_pressure_readings.find(params[:id])
  end

  def blood_pressure_reading_params
    params.expect(blood_pressure_reading: [ :systolic, :diastolic, :date ])
  end
end
