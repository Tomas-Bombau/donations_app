defmodule PuenteAppWeb.UserRegistrationController do
  use PuenteAppWeb, :controller

  alias PuenteApp.Accounts
  alias PuenteApp.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    # Only donors can register through public registration
    user_params = Map.put(user_params, "role", "donor")

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        conn
        |> put_flash(
          :info,
          "Se envio un email a #{user.email}. Por favor confirma tu cuenta para poder iniciar sesion."
        )
        |> redirect(to: ~p"/users/log-in")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
