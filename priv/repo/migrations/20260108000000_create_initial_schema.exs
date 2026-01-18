defmodule PuenteApp.Repo.Migrations.CreateInitialSchema do
  use Ecto.Migration

  def change do
    # Extensions
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"", ""

    # Enum types
    execute "CREATE TYPE user_role AS ENUM ('donor', 'organization', 'super_admin')", "DROP TYPE user_role"
    execute "CREATE TYPE request_status AS ENUM ('draft', 'active', 'completed', 'closed')", "DROP TYPE request_status"

    # ============================================
    # USERS
    # ============================================
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
      add :image_path, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create index(:users, [:role])
    create index(:users, [:admin_approved_at])
    create index(:users, [:archived])

    # ============================================
    # USERS TOKENS
    # ============================================
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

    # ============================================
    # ORGANIZATIONS
    # ============================================
    create table(:organizations, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :organization_role, :string, null: false
      add :organization_name, :string, null: false
      add :address, :string
      add :province, :string
      add :municipality, :string
      add :lat, :float
      add :lng, :float
      add :has_legal_entity, :boolean, default: false
      add :cbu, :string
      add :payment_alias, :string
      add :image_path, :string
      add :facebook, :string
      add :instagram, :string
      add :activities, :text
      add :audience, :string
      add :reach, :string

      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:user_id])
    create index(:organizations, [:province])
    create index(:organizations, [:municipality])

    # ============================================
    # CATEGORIES
    # ============================================
    create table(:categories, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :name, :string, null: false
      add :description, :string
      add :active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:categories, [:name])
    create index(:categories, [:active])

    # ============================================
    # REQUESTS
    # ============================================
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
      add :amount_raised, :decimal, default: 0, precision: 10, scale: 2, null: false
      add :closing_message, :text
      add :outcome_description, :text
      add :outcome_images, {:array, :string}, default: []
      add :closed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:requests, [:organization_id])
    create index(:requests, [:category_id])
    create index(:requests, [:status])
    create index(:requests, [:organization_id, :inserted_at])
    create index(:requests, [:deadline])
    create index(:requests, [:organization_id, :status],
      where: "status = 'completed'",
      name: :requests_pending_closure_index
    )

    # ============================================
    # DONATIONS
    # ============================================
    create table(:donations, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :donor_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :request_id, references(:requests, type: :uuid, on_delete: :restrict), null: false
      add :amount, :decimal, null: false, precision: 12, scale: 2

      timestamps(type: :utc_datetime)
    end

    create index(:donations, [:donor_id])
    create index(:donations, [:request_id])
  end
end
