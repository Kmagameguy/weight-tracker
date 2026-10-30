class JournalEntriesController < ApplicationController
  before_action :set_journal_entry, only: %i[ edit update destroy ]

  def create
    @journal_entry = Current.user.journal_entries.build(journal_entry_params)

    if @journal_entry.save
      redirect_to day_path_for(@journal_entry)
    else
      redirect_to(
        day_path_for(Date.parse(params[:journal_entry][:date])),
        alert: @journal_entry.errors.full_messages.to_sentence
      )
    end
  end

  def edit; end

  def update
    if @journal_entry.update(journal_entry_params)
      redirect_to day_path_for(@journal_entry)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @date = @journal_entry.date
    @journal_entry.destroy!

    redirect_to day_path_for(@date)
  end

  private

  def set_journal_entry
    @journal_entry = Current.user.journal_entries.find(params[:id])
  end

  def journal_entry_params
    params.expect(journal_entry: [ :note, :date ])
  end
end
