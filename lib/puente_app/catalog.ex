defmodule PuenteApp.Catalog do
  @moduledoc """
  The Catalog context for managing categories.
  """

  import Ecto.Query, warn: false
  alias PuenteApp.Repo
  alias PuenteApp.Catalog.Category

  @doc """
  Returns the list of all categories.
  """
  def list_categories do
    Category
    |> order_by(asc: :name)
    |> Repo.all()
  end

  @doc """
  Returns the list of active categories.
  """
  def list_active_categories do
    Category
    |> where(active: true)
    |> order_by(asc: :name)
    |> Repo.all()
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.
  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category.
  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.
  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deactivates a category.
  """
  def deactivate_category(%Category{} = category) do
    category
    |> Category.changeset(%{active: false})
    |> Repo.update()
  end

  @doc """
  Activates a category.
  """
  def activate_category(%Category{} = category) do
    category
    |> Category.changeset(%{active: true})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.
  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end
end
