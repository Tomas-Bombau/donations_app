defmodule AppDonationWeb.Admin.OrganizationControllerTest do
  use AppDonationWeb.ConnCase, async: true

  import AppDonation.AccountsFixtures

  alias AppDonation.Organizations

  describe "GET /admin/organizations/:id" do
    setup do
      org_user = organization_user_fixture()
      {:ok, organization} =
        Organizations.create_organization(%{
          user_id: org_user.id,
          organization_name: "Test Organization",
          organization_role: "presidente",
          province: "CABA",
          address: "123 Test St"
        })
      # The route expects USER id, not organization id
      %{org_user: org_user, organization: organization}
    end

    test "redirects if user is not logged in", %{conn: conn, org_user: org_user} do
      conn = get(conn, ~p"/admin/organizations/#{org_user.id}")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "redirects if user is not an admin", %{conn: conn, org_user: org_user} do
      conn =
        conn
        |> log_in_user(user_fixture())
        |> get(~p"/admin/organizations/#{org_user.id}")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "permiso"
    end

    test "renders organization details for admin user", %{conn: conn, org_user: org_user, organization: organization} do
      conn =
        conn
        |> log_in_user(admin_user_fixture())
        |> get(~p"/admin/organizations/#{org_user.id}")

      assert html_response(conn, 200) =~ organization.organization_name
    end
  end
end
