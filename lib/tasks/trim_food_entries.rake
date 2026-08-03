namespace :food_entries do
  desc "Trim all whitespace from food entry names"
  task trim: :environment do
    Rails.application.eager_load!

    adjusted_entries = []

    FoodEntry.all.each do |food_entry|
      name = food_entry.name
      squished_name = name&.squish
      next unless name != squished_name

      food_entry.update_column(:name, name.squish)
      adjusted_entries << { id: food_entry.id, original_name: name, trimmed_name: food_entry.reload.name }
    end

    if adjusted_entries.any?
      puts "Trimmed the following entries [id, original_name, trimmed_name]:"
      pp adjusted_entries
    end
  end
end
