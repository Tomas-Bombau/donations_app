defmodule AppDonation.Repo.Migrations.AddImagePathToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :image_path, :string
    end
  end
end
