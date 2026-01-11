defmodule PuenteAppWeb.UserConfirmationControllerTest do
  use PuenteAppWeb.ConnCase, async: true

  import PuenteApp.AccountsFixtures

  alias PuenteApp.Accounts

  setup do
    %{user: unconfirmed_user_fixture()}
  end

  describe "GET /users/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, ~p"/users/confirm")
      response = html_response(conn, 200)
      assert response =~ "Reenviar email de confirmacion"
    end
  end

  describe "POST /users/confirm" do
    test "sends a new confirmation token", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/confirm", %{
          "user" => %{"email" => user.email}
        })

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Si tu email esta en nuestro sistema"
    end

    test "does not send confirmation token if user is already confirmed", %{conn: conn} do
      user = user_fixture()

      conn =
        post(conn, ~p"/users/confirm", %{
          "user" => %{"email" => user.email}
        })

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Si tu email esta en nuestro sistema"
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/users/confirm", %{
          "user" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Si tu email esta en nuestro sistema"
    end
  end

  describe "GET /users/confirm/:token" do
    test "confirms the user with a valid token", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_confirmation_instructions(user, url)
        end)

      conn = get(conn, ~p"/users/confirm/#{token}")

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Email confirmado exitosamente"

      # Verify user is confirmed
      assert Accounts.get_user!(user.id).confirmed_at
    end

    test "does not confirm with invalid token", %{conn: conn} do
      conn = get(conn, ~p"/users/confirm/invalid-token")

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "invalido o ha expirado"
    end
  end
end
