defmodule PuenteApp.CatalogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PuenteApp.Catalog` context.
  """

  alias PuenteApp.Catalog

  def valid_category_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Categoría #{System.unique_integer()}",
      description: "Descripción de la categoría",
      active: true
    })
  end

  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> valid_category_attributes()
      |> Catalog.create_category()

    category
  end
end
