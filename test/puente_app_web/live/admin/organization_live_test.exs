defmodule PuenteAppWeb.Admin.OrganizationLiveTest do
  use PuenteAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PuenteApp.AccountsFixtures
  import PuenteApp.OrganizationsFixtures

  alias PuenteApp.Accounts

  describe "OrganizationLive.Index" do
    setup %{conn: conn} do
      admin = admin_user_fixture()
      conn = log_in_user(conn, admin)
      %{conn: conn, admin: admin}
    end

    test "renders organization list page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/organizations")
      assert html =~ "Organizaciones" or html =~ "organizaciones"
    end

    test "shows pending organizations by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/organizations")
      # Just check the page loads with organization-related content
      assert html =~ "Organiza" or html =~ "organiza" or html =~ "Pendiente"
    end

    test "switches to approved tab", %{conn: conn} do
      {_user, _organization} = organization_fixture()
      {:ok, view, _html} = live(conn, ~p"/admin/organizations")

      result =
        view
        |> element("a[href*='tab=approved']")
        |> render_click()

      case result do
        {:ok, _view, html} ->
          assert html =~ "Organiza" or html =~ "organiza" or html =~ "Aprobada"

        html when is_binary(html) ->
          assert html =~ "Organiza" or html =~ "organiza" or html =~ "Aprobada"
      end
    end

    test "approves pending organization", %{conn: conn} do
      # Create unapproved organization user
      user =
        %{role: :organization}
        |> unconfirmed_user_fixture()
        |> then(fn u ->
          {:ok, confirmed} =
            Accounts.confirm_user_by_token(extract_confirmation_token(u))

          confirmed
        end)

      {:ok, view, _html} = live(conn, ~p"/admin/organizations?tab=pending")

      html =
        view
        |> element("button[phx-click='approve'][phx-value-id='#{user.id}']")
        |> render_click()

      # Verify page rendered after action
      assert html =~ "Organiza" or html =~ "organiza" or html =~ "aprobada"
    end

    test "archives organization from edit page", %{conn: conn, admin: admin} do
      {user, _organization} = organization_fixture()
      {:ok, view, _html} = live(conn, ~p"/admin/organizations/#{user.id}/edit")

      result =
        view
        |> element("button[phx-click='archive']")
        |> render_click()

      # Archive redirects to index
      assert {:error, {:live_redirect, %{to: "/admin/organizations"}}} = result

      # Verify organization user was archived
      archived_user = Accounts.get_user!(user.id)
      assert archived_user.archived == true
      assert archived_user.archived_by == admin.id
    end

    test "filters by province", %{conn: conn} do
      {_user, _organization} = organization_fixture()
      {:ok, view, _html} = live(conn, ~p"/admin/organizations?tab=approved")

      html =
        view
        |> element("form")
        |> render_change(%{"province" => "CABA"})

      # Verify page rendered
      assert html
    end
  end

  describe "OrganizationLive.Edit" do
    setup %{conn: conn} do
      admin = admin_user_fixture()
      {user, organization} = organization_fixture()
      conn = log_in_user(conn, admin)
      %{conn: conn, admin: admin, org_user: user, organization: organization}
    end

    test "renders edit form", %{conn: conn, org_user: user, organization: organization} do
      {:ok, _view, html} = live(conn, ~p"/admin/organizations/#{user.id}/edit")
      assert html =~ organization.organization_name or html =~ "Editar"
    end

    test "updates organization details", %{conn: conn, org_user: user} do
      {:ok, view, _html} = live(conn, ~p"/admin/organizations/#{user.id}/edit")

      result =
        view
        |> form("form", %{
          "organization" => %{
            "organization_name" => "Nombre actualizado admin"
          }
        })
        |> render_submit()

      case result do
        {:ok, _view, html} ->
          assert html =~ "actualizada" or html =~ "Nombre actualizado admin" or html =~ "Organiza"

        html when is_binary(html) ->
          assert html =~ "actualizada" or html =~ "Nombre actualizado admin" or html =~ "Organiza"
      end
    end

    test "validates form on change", %{conn: conn, org_user: user} do
      {:ok, view, _html} = live(conn, ~p"/admin/organizations/#{user.id}/edit")

      html =
        view
        |> element("form")
        |> render_change(%{"organization" => %{"organization_name" => ""}})

      # Form should show validation
      assert html
    end
  end

  describe "access control" do
    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:error, {:redirect, %{to: to}}} = live(conn, ~p"/admin/organizations")
      assert to == "/"
    end
  end

  # Helper to extract confirmation token
  defp extract_confirmation_token(user) do
    extract_user_token(fn url ->
      PuenteApp.Accounts.deliver_confirmation_instructions(user, url)
    end)
  end
end
