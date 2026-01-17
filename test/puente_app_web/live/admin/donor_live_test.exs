defmodule PuenteAppWeb.Admin.DonorLiveTest do
  use PuenteAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PuenteApp.AccountsFixtures

  alias PuenteApp.Accounts

  describe "DonorLive.Index" do
    setup %{conn: conn} do
      admin = admin_user_fixture()
      conn = log_in_user(conn, admin)
      %{conn: conn, admin: admin}
    end

    test "renders donor list page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/donors")
      assert html =~ "Colaboradores"
    end

    test "lists active donors", %{conn: conn} do
      donor = user_fixture(%{first_name: "Juan", last_name: "Donante"})
      {:ok, _view, html} = live(conn, ~p"/admin/donors")
      assert html =~ donor.first_name
    end

    test "switches to archived tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/donors")

      result =
        view
        |> element("a[href*='tab=archived']")
        |> render_click()

      case result do
        {:ok, _view, html} ->
          assert html =~ "Archivados" or html =~ "archivados" or html =~ "Donantes"

        html when is_binary(html) ->
          assert html =~ "Archivados" or html =~ "archivados" or html =~ "Donantes"
      end
    end

    test "archives donor from edit page", %{conn: conn, admin: admin} do
      donor = user_fixture()
      {:ok, view, _html} = live(conn, ~p"/admin/donors/#{donor.id}/edit")

      result =
        view
        |> element("button[phx-click='archive']")
        |> render_click()

      # Archive redirects to index
      assert {:error, {:live_redirect, %{to: "/admin/donors"}}} = result

      # Verify donor was archived
      archived_donor = Accounts.get_user!(donor.id)
      assert archived_donor.archived == true
      assert archived_donor.archived_by == admin.id
    end

    test "unarchives donor from edit page", %{conn: conn, admin: admin} do
      donor = user_fixture()
      {:ok, _} = Accounts.archive_user(donor, admin.id)

      {:ok, view, _html} = live(conn, ~p"/admin/donors/#{donor.id}/edit")

      result =
        view
        |> element("button[phx-click='unarchive']")
        |> render_click()

      # Unarchive may redirect or stay on page
      case result do
        {:error, {:live_redirect, %{to: "/admin/donors"}}} ->
          # Verify donor was unarchived
          unarchived_donor = Accounts.get_user!(donor.id)
          assert unarchived_donor.archived == false

        html when is_binary(html) ->
          # Stayed on page, verify flash message and donor state
          assert html =~ "desarchivado"
          unarchived_donor = Accounts.get_user!(donor.id)
          assert unarchived_donor.archived == false
      end
    end

    test "paginates results", %{conn: conn} do
      # Create multiple donors (more than per_page which is 5)
      for i <- 1..10 do
        user_fixture(%{first_name: "Donor#{i}"})
      end

      {:ok, _view, html} = live(conn, ~p"/admin/donors?page=1")
      # First page should show some donors
      assert html

      # Verify pagination exists (either page number or navigation)
      assert html =~ "phx-click=\"change_page\"" or html =~ "page=2" or html =~ "Mostrando"
    end
  end

  describe "access control" do
    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:error, {:redirect, %{to: to}}} = live(conn, ~p"/admin/donors")
      assert to == "/"
    end

    test "redirects unauthenticated users", %{conn: conn} do
      {:error, {:redirect, %{to: to}}} = live(conn, ~p"/admin/donors")
      # Admin routes redirect to "/" for unauthenticated users (via on_mount :admin)
      assert to == "/"
    end
  end
end
