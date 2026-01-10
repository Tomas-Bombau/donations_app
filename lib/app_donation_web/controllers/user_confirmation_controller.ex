defmodule AppDonationWeb.UserConfirmationController do
  use AppDonationWeb, :controller

  alias AppDonation.Accounts

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      if is_nil(user.confirmed_at) do
        Accounts.deliver_confirmation_instructions(
          user,
          &url(~p"/users/confirm/#{&1}")
        )
      end
    end

    # Always show the same message to prevent user enumeration
    conn
    |> put_flash(
      :info,
      "Si tu email esta en nuestro sistema y no fue confirmado, recibiras un email con instrucciones en breve."
    )
    |> redirect(to: ~p"/users/log-in")
  end

  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user_by_token(token) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Email confirmado exitosamente. Ya podes iniciar sesion.")
        |> redirect(to: ~p"/users/log-in")

      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "El enlace de confirmacion es invalido o ha expirado.")
        |> redirect(to: ~p"/users/log-in")
    end
  end
end
