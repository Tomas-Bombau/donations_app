defmodule AppDonation.Repo.Migrations.CreateDonations do
  use Ecto.Migration

  def up do
    execute "CREATE TYPE donation_status AS ENUM ('pending', 'completed', 'cancelled')"

    create table(:donations, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :donor_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :request_id, references(:requests, type: :uuid, on_delete: :restrict), null: false
      add :amount, :decimal, null: false, precision: 12, scale: 2
      add :status, :donation_status, null: false, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create index(:donations, [:donor_id])
    create index(:donations, [:request_id])
    create index(:donations, [:status])
  end

  def down do
    drop table(:donations)
    execute "DROP TYPE donation_status"
  end
end
