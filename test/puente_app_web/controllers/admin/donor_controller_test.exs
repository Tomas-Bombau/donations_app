defmodule PuenteAppWeb.Admin.DonorControllerTest do
  use PuenteAppWeb.ConnCase, async: true

  import PuenteApp.AccountsFixtures

  describe "GET /admin/donors/:id" do
    setup do
      donor = user_fixture()
      %{donor: donor}
    end

    test "redirects if user is not logged in", %{conn: conn, donor: donor} do
      conn = get(conn, ~p"/admin/donors/#{donor.id}")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "redirects if user is not an admin", %{conn: conn, donor: donor} do
      conn =
        conn
        |> log_in_user(user_fixture())
        |> get(~p"/admin/donors/#{donor.id}")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permiso"
    end

    test "renders donor details for admin user", %{conn: conn, donor: donor} do
      conn =
        conn
        |> log_in_user(admin_user_fixture())
        |> get(~p"/admin/donors/#{donor.id}")

      assert html_response(conn, 200) =~ donor.first_name
    end
  end
end
