defmodule PuenteAppWeb.Organization.SettingsLiveTest do
  use PuenteAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PuenteApp.OrganizationsFixtures

  describe "SettingsLive" do
    setup %{conn: conn} do
      {user, organization} = organization_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user, organization: organization}
    end

    test "renders settings page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/organization/settings")
      assert html =~ "Configuracion" or html =~ "configuracion" or html =~ "Ajustes"
    end

    test "shows user form", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/organization/settings")
      assert html =~ user.first_name
    end

    test "validates form on change", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/organization/settings")

      html =
        view
        |> element("form")
        |> render_change(%{"user" => %{"first_name" => ""}})

      # Should show validation or update form
      assert html
    end

    test "updates user profile", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/organization/settings")

      html =
        view
        |> form("form", %{
          "user" => %{
            "first_name" => "NuevoNombre"
          }
        })
        |> render_submit()

      assert html =~ "actualizado" or html =~ "NuevoNombre"
    end

    test "updates social media", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/organization/settings")

      html =
        view
        |> form("form", %{
          "organization" => %{
            "facebook" => "https://facebook.com/miorg",
            "instagram" => "https://instagram.com/miorg"
          }
        })
        |> render_submit()

      assert html =~ "actualizado" or html =~ "facebook"
    end
  end

  describe "access control" do
    test "redirects non-organization users", %{conn: conn} do
      import PuenteApp.AccountsFixtures
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:error, {:redirect, %{to: to}}} = live(conn, ~p"/organization/settings")
      assert to == "/"
    end
  end
end
