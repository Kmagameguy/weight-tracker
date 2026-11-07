# frozen_string_literal: true

# This lists models that contribute to the sync API.

module SyncRegistry
  module_function

  def models
    Rails.application.eager_load! unless Rails.application.config.eager_load

    syncable_models = ApplicationRecord.descendants.select { |model| model < Syncable }
    syncable_models.sort_by { |model| [ ancestry_depth(model), model.name ] }
  end

  # e.g. "food_entry" => FoodEntry
  def by_type
    models.index_by { |model| model.sync_type }
  end

  def ancestry_depth(model)
    parent_model = model.sync_config[:parent]
    return 0 unless parent_model

    1 + ancestry_depth(model.reflect_on_association(parent_model).klass)
  end
end
