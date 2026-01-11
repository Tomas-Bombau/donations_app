defmodule PuenteAppWeb.UserSessionController do
  use PuenteAppWeb, :controller

  alias PuenteApp.Accounts
  alias PuenteApp.Accounts.User
  alias PuenteAppWeb.UserAuth

  def new(conn, _params) do
    email = get_in(conn.assigns, [:current_scope, Access.key(:user), Access.key(:email)])
    form = Phoenix.Component.to_form(%{"email" => email}, as: "user")

    render(conn, :new, form: form)
  end

  # email + password login
  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      form = Phoenix.Component.to_form(user_params, as: "user")

      cond do
        is_nil(user.confirmed_at) ->
          conn
          |> put_flash(
            :error,
            "Debes confirmar tu email antes de iniciar sesion. " <>
              "<a href=\"/users/confirm\" class=\"underline\">Reenviar email de confirmacion</a>"
            |> Phoenix.HTML.raw()
          )
          |> render(:new, form: form)

        User.needs_admin_approval?(user) ->
          conn
          |> put_flash(:error, "Tu cuenta esta pendiente de aprobacion por un administrador.")
          |> render(:new, form: form)

        true ->
          conn
          |> put_flash(:info, "Bienvenido de nuevo!")
          |> UserAuth.log_in_user(user, user_params)
      end
    else
      form = Phoenix.Component.to_form(user_params, as: "user")

      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Email o contrasena invalidos")
      |> render(:new, form: form)
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Sesion cerrada exitosamente.")
    |> UserAuth.log_out_user()
  end
end
