class WeightEntriesController < ApplicationController
  before_action :set_weight_entry, only: %i[edit update destroy]

  def create
    @weight_entry = Current.user.weight_entries.build(weight_entry_params)
    if @weight_entry.save
      redirect_to day_path_for(@weight_entry)
    else
      redirect_to day_path_for(Date.parse(params[:weight_entry][:date])), alert: @weight_entry.errors.full_messages.to_sentence
    end
  end

  def edit; end

  def update
    if @weight_entry.update(weight_entry_params)
      redirect_to day_path_for(@weight_entry)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @date = @weight_entry.date
    @weight_entry.destroy!

    redirect_to day_path_for(@date)
  end

  private

  def set_weight_entry
    @weight_entry = Current.user.weight_entries.find(params[:id])
  end

  def weight_entry_params
    params.expect(weight_entry: [:weight, :date, :user_id])
  end
end
