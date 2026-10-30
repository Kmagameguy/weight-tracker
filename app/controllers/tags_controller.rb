class TagsController < ApplicationController
  before_action :set_tag, only: %i[ edit update destroy ]

  def create
    @tag = Current.user.tags.build(tag_params)

    if @tag.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to profile_path, notice: "Tag created." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_tag_form",
            partial: "tags/form",
            formats: [ :html ],
            locals: { tag: @tag, url: tags_path }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to profile_path, alert: @tag.errors.full_messages.to_sentence }
      end
    end
  end

  def edit; end

  def update
    if @tag.update(tag_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to profile_path, notice: "Tag updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tag.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to profile_path, notice: "Tag removed.", status: :see_other }
    end
  end

  private

  def set_tag
    @tag = Current.user.tags.find(params[:id])
  end

  def tag_params
    params.expect(tag: [ :name ])
  end
end
