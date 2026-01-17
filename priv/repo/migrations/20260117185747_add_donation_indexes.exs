defmodule PuenteApp.Repo.Migrations.AddDonationIndexes do
  use Ecto.Migration

  def change do
    # Index for filtering donations by donor (common query)
    create_if_not_exists index(:donations, [:donor_id])

    # Index for filtering donations by request (common query)
    create_if_not_exists index(:donations, [:request_id])
  end
end
