class CreateSyncTables < ActiveRecord::Migration[8.1]
  def change
    create_table :deletions do |t|
      t.integer :user_id,     null: false
      t.string  :record_type, null: false
      t.string  :uuid,        null: false
      t.datetime :deleted_at, null: false
    end
    add_index :deletions, [ :user_id, :deleted_at ]

    create_table :api_tokens do |t|
      t.references :user,         null: false, foreign_key: true
      t.string     :token_digest, null: false
      t.string     :name
      t.datetime   :last_used_at

      t.timestamps
    end
    add_index :api_tokens, :token_digest, unique: true
  end
end
