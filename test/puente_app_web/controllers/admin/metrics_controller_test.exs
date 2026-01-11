defmodule PuenteAppWeb.Admin.MetricsControllerTest do
  use PuenteAppWeb.ConnCase, async: true

  import PuenteApp.AccountsFixtures

  describe "GET /admin/metrics" do
    test "redirects if user is not logged in", %{conn: conn} do
      conn = get(conn, ~p"/admin/metrics")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "redirects if user is not an admin", %{conn: conn} do
      conn =
        conn
        |> log_in_user(user_fixture())
        |> get(~p"/admin/metrics")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permiso"
    end

    test "renders metrics page for admin user", %{conn: conn} do
      conn =
        conn
        |> log_in_user(admin_user_fixture())
        |> get(~p"/admin/metrics")

      assert html_response(conn, 200)
    end
  end
end
