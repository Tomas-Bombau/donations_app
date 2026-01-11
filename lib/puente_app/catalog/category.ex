defmodule PuenteApp.Catalog.Category do
  use PuenteApp, :schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :description, :string
    field :active, :boolean, default: true

    has_many :requests, PuenteApp.Requests.Request

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description, :active])
    |> validate_required([:name])
    |> validate_length(:name, max: 100)
    |> validate_length(:description, max: 500)
    |> unique_constraint(:name)
  end
end
