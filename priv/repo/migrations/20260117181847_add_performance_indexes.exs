defmodule PuenteApp.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Users table indexes for admin filtering
    create_if_not_exists index(:users, [:role])
    create_if_not_exists index(:users, [:admin_approved_at])
    create_if_not_exists index(:users, [:archived])

    # Organizations table indexes for geographic filtering
    create_if_not_exists index(:organizations, [:province])
    create_if_not_exists index(:organizations, [:municipality])

    # Requests table indexes for ordering and filtering
    create_if_not_exists index(:requests, [:organization_id, :inserted_at])
    create_if_not_exists index(:requests, [:deadline])

    # Categories table indexes for search and filtering
    create_if_not_exists index(:categories, [:name])
    create_if_not_exists index(:categories, [:active])
  end
end
