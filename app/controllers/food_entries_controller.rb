class FoodEntriesController < ApplicationController
  LIMIT_MAX = 50
  DEFAULT_LIMIT = 8
  before_action :set_food_entry, only: %i[show edit update destroy]

  def index
    @food_entries = begin
      if search_query.present?
        Current.user
          .food_entries
          .then { |scope| filter_by_query(scope) }
          .select(:name, :calories)
          .order(date: :desc)
          .limit(LIMIT_MAX)
          .uniq { |entry| entry.name.downcase }
          .first(search_limit)
      else
        FoodEntry.none
      end
    end

    if requested_search_limit > LIMIT_MAX
      flash.now[:alert] = "Limit of #{requested_search_limit} is too large. Falling back to max limit: #{LIMIT_MAX}"
    end

    render layout: false
  end

  def show
    render partial: "food_entries/food_entry", locals: { food_entry: @food_entry }
  end

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

  def filter_by_query(scope)
    return scope unless search_query.present?

    scope.where("LOWER(name) LIKE ?", "%#{search_query}%")
  end

  def search_limit
    [ requested_search_limit, LIMIT_MAX ].min
  end

  def requested_search_limit
    (params[:limit].presence || DEFAULT_LIMIT).to_i
  end

  def search_query
    FoodEntry.sanitize_sql_like(params[:query].to_s.downcase)
  end

  def set_food_entry
    @food_entry = Current.user.food_entries.find(params[:id])
  end

  def food_entry_params
    params.expect(food_entry: [ :name, :calories, :date ])
  end
end
