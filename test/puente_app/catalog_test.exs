defmodule PuenteApp.CatalogTest do
  use PuenteApp.DataCase

  alias PuenteApp.Catalog
  alias PuenteApp.Catalog.Category

  import PuenteApp.CatalogFixtures

  describe "list_categories/0" do
    test "returns all categories ordered by name" do
      category1 = category_fixture(%{name: "Zeta"})
      category2 = category_fixture(%{name: "Alfa"})

      categories = Catalog.list_categories()
      assert length(categories) == 2
      assert hd(categories).id == category2.id
      assert List.last(categories).id == category1.id
    end

    test "returns empty list when no categories" do
      assert Catalog.list_categories() == []
    end
  end

  describe "list_active_categories/0" do
    test "returns only active categories" do
      active = category_fixture(%{active: true})
      _inactive = category_fixture(%{active: false})

      categories = Catalog.list_active_categories()
      assert length(categories) == 1
      assert hd(categories).id == active.id
    end
  end

  describe "get_category!/1" do
    test "returns category with given id" do
      category = category_fixture()
      assert Catalog.get_category!(category.id).id == category.id
    end

    test "raises when category not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Catalog.get_category!(Ecto.UUID.generate())
      end
    end
  end

  describe "create_category/1" do
    test "creates category with valid data" do
      attrs = %{name: "Nueva Categoría", description: "Descripción"}
      assert {:ok, %Category{} = category} = Catalog.create_category(attrs)
      assert category.name == "Nueva Categoría"
      assert category.description == "Descripción"
      assert category.active == true
    end

    test "returns error changeset with invalid data" do
      assert {:error, %Ecto.Changeset{}} = Catalog.create_category(%{})
    end

    test "validates name is required" do
      assert {:error, changeset} = Catalog.create_category(%{description: "Solo descripción"})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "validates name uniqueness" do
      category_fixture(%{name: "Única"})
      assert {:error, changeset} = Catalog.create_category(%{name: "Única"})
      assert "has already been taken" in errors_on(changeset).name
    end

    test "validates name max length" do
      long_name = String.duplicate("a", 101)
      assert {:error, changeset} = Catalog.create_category(%{name: long_name})
      assert "should be at most 100 character(s)" in errors_on(changeset).name
    end
  end

  describe "update_category/2" do
    test "updates category with valid data" do
      category = category_fixture()
      attrs = %{name: "Nombre Actualizado"}

      assert {:ok, %Category{} = updated} = Catalog.update_category(category, attrs)
      assert updated.name == "Nombre Actualizado"
    end

    test "returns error changeset with invalid data" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Catalog.update_category(category, %{name: ""})
    end
  end

  describe "deactivate_category/1" do
    test "sets category as inactive" do
      category = category_fixture(%{active: true})
      assert {:ok, %Category{} = updated} = Catalog.deactivate_category(category)
      assert updated.active == false
    end
  end

  describe "activate_category/1" do
    test "sets category as active" do
      category = category_fixture(%{active: false})
      assert {:ok, %Category{} = updated} = Catalog.activate_category(category)
      assert updated.active == true
    end
  end

  describe "change_category/2" do
    test "returns a changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Catalog.change_category(category)
    end
  end
end
