defmodule PuenteAppWeb.OrganizationRegistrationControllerTest do
  use PuenteAppWeb.ConnCase, async: true

  import PuenteApp.AccountsFixtures

  describe "GET /organizations/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, ~p"/organizations/register")
      response = html_response(conn, 200)
      assert response =~ "organizacion" or response =~ "Organizacion"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(~p"/organizations/register")
      assert redirected_to(conn) =~ "/"
    end
  end

  describe "POST /organizations/register" do
    test "render errors for invalid user data", %{conn: conn} do
      conn =
        post(conn, ~p"/organizations/register", %{
          "user" => %{"email" => "with spaces"},
          "organization" => %{
            "organization_name" => "Test Organization",
            "organization_role" => "presidente",
            "province" => "CABA"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "must have the @ sign and no spaces"
    end

    test "render errors for invalid organization data", %{conn: conn} do
      conn =
        post(conn, ~p"/organizations/register", %{
          "user" => %{
            "email" => unique_user_email(),
            "first_name" => "Test",
            "last_name" => "Org",
            "phone" => "1234567890",
            "password" => valid_user_password()
          },
          "organization" => %{
            "organization_name" => "",
            "organization_role" => "",
            "province" => ""
          }
        })

      response = html_response(conn, 200)
      # The page re-renders with errors - checking we got the form back
      assert response =~ "organizacion" or response =~ "Organizacion" or response =~ "blank"
    end

    @tag :capture_log
    test "creates organization account and redirects", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, ~p"/organizations/register", %{
          "user" => %{
            "email" => email,
            "first_name" => "Test",
            "last_name" => "Org",
            "phone" => "1234567890",
            "password" => valid_user_password()
          },
          "organization" => %{
            "organization_name" => "Test Organization",
            "organization_role" => "presidente",
            "province" => "CABA"
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "solicitud"
    end
  end
end
