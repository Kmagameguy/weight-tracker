require "test_helper"

class SyncRegistryTest < ActiveSupport::TestCase
  NOT_SYNCED_TABLES = %w[sessions api_tokens sync_events].freeze

  setup do
    @connection = ActiveRecord::Base.connection
    @subject    = SyncRegistry
  end

  def tables_with(column)
    @connection.tables.select do |table|
      @connection.columns(table).any? { |definition| definition.name == column }
    end
  end

  def synced_tables
    @subject.models.map(&:table_name)
  end

  it "only registers models that have a uuid attribute" do
    assert_equal (tables_with("uuid") - NOT_SYNCED_TABLES).sort, synced_tables.sort
  end

  it "must ensure synchronization is configured for every user-owned table" do
    misconfigured_tables = tables_with("user_id") - synced_tables - NOT_SYNCED_TABLES

    assert_empty(
      misconfigured_tables,
      "Decide whether #{misconfigured_tables.join(', ')} " \
      "syncs data (Syncable + syncs declaration) or add it to NOT_SYNCED_TABLES"
    )
  end

  it "must ensure uuids are unique" do
    @subject.models.each do |model|
      indexes = @connection.indexes(model.table_name)
      unique_on_uuid = indexes.any? { |index| index.unique && index.columns == [ "uuid" ] }

      assert unique_on_uuid, "#{model.name} needs a unique index on uuid"
    end
  end

  it "only accepts columns and parent associations that exist" do
    @subject.models.each do |model|
      config = model.sync_config

      assert_empty config[:fields] - model.column_names, "#{model.name} syncs a column that doesn't exist"
      if config[:parent]
        assert model.reflect_on_association(config[:parent]), "#{model.name} declares a missing parent"
      end
    end
  end

  it "requires unique_by whenever a table has another unique index" do
    @subject.models.each do |model|
      indexes      = @connection.indexes(model.table_name)
      other_unique = indexes.select { |index| index.unique && index.columns != [ "uuid" ] }

      if other_unique.any?
        assert model.sync_config[:unique_by], "#{model.name} has a unique index; declare unique_by:"
      end
    end
  end

  it "ensures associated records are scoped to their user" do
    user = users(:one)

    @subject.models.each do |model|
      user_owned_association = model.owned_by(user).to_a

      assert_not_empty user_owned_association, "add a fixture for #{model.name} owned by users(:one)"
      assert(
        user_owned_association.all? { |record| record.sync_owner_id == user.id },
        "#{model.name}: owned_by and sync_owner_id don't match"
      )
    end
  end

  it "ensures bulk deletes cascade properly through callbacks" do
    @subject.models.each do |model|
      model.reflect_on_all_associations(:has_many).each do |association|
        assert_not_includes(
          %i[ delete delete_all nullify ], association.options[:dependent],
          "#{model.name}##{association.name} would skip the sync log; use dependent: :destroy"
        )
      end
    end
  end

  it "ensures parent -> subordinate trees are ordered properly" do
    assert_operator @subject.models.index(Tag), :<, @subject.models.index(DayTag)
  end
end
