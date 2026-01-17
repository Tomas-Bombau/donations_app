defmodule PuenteApp.Repo.Migrations.RemoveStatusFromDonations do
  use Ecto.Migration

  def change do
    alter table(:donations) do
      remove :status, :string, default: "pending"
    end
  end
end
