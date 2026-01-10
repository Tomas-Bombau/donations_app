defmodule AppDonation.Repo.Migrations.UpdateRequestStatuses do
  use Ecto.Migration

  def up do
    # Add amount_raised column (replaces funded_amount with better name)
    alter table(:requests) do
      remove :funded_amount
      add :amount_raised, :decimal, precision: 10, scale: 2, default: 0, null: false
    end

    # Create new enum type with simplified statuses
    execute "CREATE TYPE request_status_new AS ENUM ('draft', 'active', 'completed')"

    # Update existing data: funded/cancelled -> completed (only values that exist in current enum)
    execute "UPDATE requests SET status = 'completed' WHERE status IN ('funded', 'cancelled')"

    # Drop the default, change type, then set default again
    execute "ALTER TABLE requests ALTER COLUMN status DROP DEFAULT"
    execute "ALTER TABLE requests ALTER COLUMN status TYPE request_status_new USING status::text::request_status_new"
    execute "ALTER TABLE requests ALTER COLUMN status SET DEFAULT 'draft'::request_status_new"

    # Drop old type and rename new one
    execute "DROP TYPE request_status"
    execute "ALTER TYPE request_status_new RENAME TO request_status"
  end

  def down do
    # Create old enum type
    execute "CREATE TYPE request_status_old AS ENUM ('draft', 'active', 'funded', 'completed', 'cancelled')"

    # Drop the default, change type, then set default again
    execute "ALTER TABLE requests ALTER COLUMN status DROP DEFAULT"
    execute "ALTER TABLE requests ALTER COLUMN status TYPE request_status_old USING status::text::request_status_old"
    execute "ALTER TABLE requests ALTER COLUMN status SET DEFAULT 'draft'::request_status_old"

    # Drop new type and rename old one
    execute "DROP TYPE request_status"
    execute "ALTER TYPE request_status_old RENAME TO request_status"

    # Revert column changes
    alter table(:requests) do
      remove :amount_raised
      add :funded_amount, :decimal, default: 0, precision: 12, scale: 2
    end
  end
end
