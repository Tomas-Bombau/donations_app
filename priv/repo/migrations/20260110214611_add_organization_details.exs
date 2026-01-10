defmodule AppDonation.Repo.Migrations.AddOrganizationDetails do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :activities, :text
      add :audience, :string
      add :reach, :string
    end
  end
end
