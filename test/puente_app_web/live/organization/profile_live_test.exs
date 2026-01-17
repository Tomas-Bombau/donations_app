defmodule PuenteAppWeb.Organization.ProfileLiveTest do
  use PuenteAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PuenteApp.OrganizationsFixtures

  describe "ProfileLive" do
    setup %{conn: conn} do
      {user, organization} = organization_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user, organization: organization}
    end

    test "renders profile page", %{conn: conn, organization: organization} do
      {:ok, _view, html} = live(conn, ~p"/organization/profile")
      assert html =~ organization.organization_name
    end

    test "shows organization details", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/organization/profile")
      assert html =~ user.first_name
      assert html =~ user.email
    end

    test "shows province", %{conn: conn, organization: organization} do
      {:ok, _view, html} = live(conn, ~p"/organization/profile")
      assert html =~ organization.province
    end
  end

  describe "access control" do
    test "redirects non-organization users", %{conn: conn} do
      import PuenteApp.AccountsFixtures
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:error, {:redirect, %{to: to}}} = live(conn, ~p"/organization/profile")
      assert to == "/"
    end
  end
end
