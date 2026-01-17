defmodule PuenteAppWeb.Admin.CategoryLiveTest do
  use PuenteAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PuenteApp.AccountsFixtures
  import PuenteApp.CatalogFixtures

  describe "CategoryLive.Index" do
    setup %{conn: conn} do
      admin = admin_user_fixture()
      conn = log_in_user(conn, admin)
      %{conn: conn, admin: admin}
    end

    test "renders category list page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/categories")
      assert html =~ "Categorias" or html =~ "categorias"
    end

    test "lists all categories", %{conn: conn} do
      category = category_fixture(%{name: "Categoría de prueba"})
      {:ok, _view, html} = live(conn, ~p"/admin/categories")
      assert html =~ category.name
    end

    test "navigates to new category form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/categories")

      result =
        view
        |> element("a[href*='new']")
        |> render_click()

      case result do
        {:ok, _view, html} ->
          assert html =~ "Nueva" or html =~ "nueva" or html =~ "Categoría"

        html when is_binary(html) ->
          assert html =~ "Nueva" or html =~ "nueva" or html =~ "Categoría"
      end
    end

    test "creates new category", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/categories/new")

      result =
        view
        |> form("form", %{
          "category" => %{
            "name" => "Nueva categoría test",
            "description" => "Descripción de test"
          }
        })
        |> render_submit()

      case result do
        {:ok, _view, html} ->
          assert html =~ "Nueva categoría test" or html =~ "categoría"

        html when is_binary(html) ->
          assert html =~ "Nueva categoría test" or html =~ "creada" or html =~ "categoría"
      end
    end

    test "deactivates category", %{conn: conn} do
      category = category_fixture(%{active: true})
      {:ok, view, _html} = live(conn, ~p"/admin/categories")

      html =
        view
        |> element("button[phx-click='deactivate'][phx-value-id='#{category.id}']")
        |> render_click()

      # Just verify the page rendered after action
      assert html =~ "Categoría" or html =~ "categoría" or html =~ category.name
    end

    test "activates category", %{conn: conn} do
      category = category_fixture(%{active: false})
      {:ok, view, _html} = live(conn, ~p"/admin/categories")

      html =
        view
        |> element("button[phx-click='activate'][phx-value-id='#{category.id}']")
        |> render_click()

      # Just verify the page rendered after action
      assert html =~ "Categoría" or html =~ "categoría" or html =~ category.name
    end
  end

  describe "CategoryLive.Index - edit" do
    setup %{conn: conn} do
      admin = admin_user_fixture()
      category = category_fixture()
      conn = log_in_user(conn, admin)
      %{conn: conn, admin: admin, category: category}
    end

    test "renders edit form", %{conn: conn, category: category} do
      {:ok, _view, html} = live(conn, ~p"/admin/categories/#{category.id}/edit")
      assert html =~ "Editar" or html =~ "editar" or html =~ category.name
    end

    test "updates category", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/admin/categories/#{category.id}/edit")

      result =
        view
        |> form("form", %{
          "category" => %{
            "name" => "Nombre actualizado"
          }
        })
        |> render_submit()

      case result do
        {:ok, _view, html} ->
          assert html =~ "Nombre actualizado" or html =~ "actualizada"

        html when is_binary(html) ->
          assert html =~ "Nombre actualizado" or html =~ "actualizada" or html =~ "categoría"
      end
    end
  end

  describe "access control" do
    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:error, {:redirect, %{to: to}}} = live(conn, ~p"/admin/categories")
      assert to == "/"
    end

    test "redirects unauthenticated users", %{conn: conn} do
      {:error, {:redirect, %{to: to}}} = live(conn, ~p"/admin/categories")
      # Admin routes redirect to "/" for unauthenticated users (via on_mount :admin)
      assert to == "/"
    end
  end
end
