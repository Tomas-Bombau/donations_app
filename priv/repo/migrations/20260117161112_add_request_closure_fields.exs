defmodule PuenteApp.Repo.Migrations.AddRequestClosureFields do
  use Ecto.Migration

  def up do
    # Add 'closed' to the request_status enum
    execute "ALTER TYPE request_status ADD VALUE 'closed'"

    # Add closure/accountability fields to requests
    alter table(:requests) do
      add :closing_message, :text
      add :outcome_description, :text
      add :outcome_images, {:array, :string}, default: []
      add :closed_at, :utc_datetime
    end

    # Index for finding requests pending closure
    create index(:requests, [:organization_id, :status],
      where: "status = 'completed'",
      name: :requests_pending_closure_index
    )
  end

  def down do
    drop index(:requests, [:organization_id, :status], name: :requests_pending_closure_index)

    alter table(:requests) do
      remove :closing_message
      remove :outcome_description
      remove :outcome_images
      remove :closed_at
    end

    # Note: PostgreSQL doesn't support removing enum values directly
    # You would need to recreate the type or leave 'closed' in place
  end
end
