defmodule AppDonation.Repo.Migrations.AddSocialMediaToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :facebook, :string
      add :instagram, :string
    end
  end
end
