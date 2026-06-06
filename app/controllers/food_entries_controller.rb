class FoodEntriesController < ApplicationController
  before_action :set_food_entry, only: %i[edit update destroy]

  def create
    @food_entry = Current.user.food_entries.build(food_entry_params)
    if @food_entry.save
      @day_presenter = DayPresenter.new(user: Current.user, date: @food_entry.date)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to day_path_for(@food_entry) }
      end
    else
      redirect_to day_path_for(Date.parse(params[:food_entry][:date])), alert: @food_entry.errors.full_messages.to_sentence
    end
  end

  def edit; end

  def update
    if @food_entry.update(food_entry_params)
      @day_presenter = DayPresenter.new(user: Current.user, date: @food_entry.date)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to day_path_for(@food_entry) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @date = @food_entry.date
    @food_entry.destroy!
    @day_presenter = DayPresenter.new(user: Current.user, date: @date)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to day_path_for(@date) }
    end
  end

  private

  def set_food_entry
    @food_entry = Current.user.food_entries.find(params[:id])
  end

  def food_entry_params
    params.expect(food_entry: [ :name, :calories, :date ])
  end
end
