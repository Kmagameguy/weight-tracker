class DayTagsController < ApplicationController
  def create
    tag     = Current.user.tags.find(day_tag_params[:tag_id])
    day_tag = tag.day_tags.find_or_create_by(date: day_tag_params[:date])
    return head :unprocessable_entity unless day_tag.persisted?

    respond_with_day_tags(day_tag.date)
  end

  def destroy
    day_tag = Current.user.day_tags.find(params[:id])
    date    = day_tag.date
    day_tag.destroy!

    respond_with_day_tags(date)
  end

  private

  def respond_with_day_tags(date)
    @day_presenter = DayPresenter.new(user: Current.user, date: date)

    respond_to do |format|
      format.turbo_stream { render :update }
      format.html { redirect_to day_path_for(date) }
    end
  end

  def day_tag_params
    params.expect(day_tag: [ :tag_id, :date ])
  end
end
