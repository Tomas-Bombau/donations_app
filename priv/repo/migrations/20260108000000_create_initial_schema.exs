defmodule AppDonation.Repo.Migrations.CreateInitialSchema do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"", ""

    execute "CREATE TYPE user_role AS ENUM ('donor', 'organization', 'super_admin')", "DROP TYPE user_role"
    execute "CREATE TYPE request_status AS ENUM ('draft', 'active', 'funded', 'completed', 'cancelled')", "DROP TYPE request_status"

    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :email, :citext, null: false
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :phone, :string
      add :role, :user_role, null: false, default: "donor"
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      add :admin_approved_at, :utc_datetime
      add :archived, :boolean, default: false
      add :archived_at, :utc_datetime
      add :archived_by, references(:users, type: :uuid, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])

    create table(:users_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    create table(:organizations, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :organization_role, :string, null: false
      add :organization_name, :string, null: false
      add :address, :string, null: false
      add :province, :string
      add :municipality, :string
      add :lat, :float
      add :lng, :float
      add :has_legal_entity, :boolean, default: false
      add :cbu, :string
      add :payment_alias, :string

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:user_id])

    create table(:categories, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :name, :string, null: false
      add :description, :string
      add :active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:categories, [:name])

    create table(:requests, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all), null: false
      add :category_id, references(:categories, type: :uuid, on_delete: :restrict), null: false
      add :title, :string, null: false
      add :description, :text, null: false
      add :amount, :decimal, null: false, precision: 12, scale: 2
      add :reference_links, {:array, :string}, default: []
      add :deadline, :date, null: false
      add :status, :request_status, null: false, default: "draft"
      add :funded_amount, :decimal, default: 0, precision: 12, scale: 2

      timestamps(type: :utc_datetime)
    end

    create index(:requests, [:organization_id])
    create index(:requests, [:category_id])
    create index(:requests, [:status])
  end
end
