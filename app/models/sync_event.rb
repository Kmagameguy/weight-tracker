# frozen_string_literal: true

# This is an append-only table. Model callbacks for create, update, and destroy
# are responsible for creating new rows via the Syncable module.
# This table's autoincrementing id is the 'cursor' used for synchronization.
# Rows are deleted if/when the associated user record is destroyed.

class SyncEvent < ApplicationRecord
end
