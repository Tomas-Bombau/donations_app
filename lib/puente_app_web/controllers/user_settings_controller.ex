defmodule PuenteAppWeb.UserSettingsController do
  use PuenteAppWeb, :controller

  alias PuenteApp.Accounts
  alias PuenteAppWeb.UserAuth

  import PuenteAppWeb.UserAuth, only: [require_sudo_mode: 2]

  plug :require_sudo_mode
  plug :assign_changesets

  def edit(conn, _params) do
    render(conn, :edit)
  end

  def update(conn, %{"action" => "update_profile"} = params) do
    %{"user" => user_params} = params
    user = conn.assigns.current_scope.user

    case Accounts.update_donor_profile(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Perfil actualizado correctamente.")
        |> redirect(to: ~p"/users/settings")

      {:error, changeset} ->
        render(conn, :edit, profile_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"user" => user_params} = params
    user = conn.assigns.current_scope.user

    case Accounts.update_user_password(user, user_params) do
      {:ok, {user, _}} ->
        conn
        |> put_flash(:info, "Contraseña actualizada correctamente.")
        |> put_session(:user_return_to, ~p"/users/settings")
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, :edit, password_changeset: changeset)
    end
  end

  defp assign_changesets(conn, _opts) do
    user = conn.assigns.current_scope.user

    conn
    |> assign(:password_changeset, Accounts.change_user_password(user))
    |> assign(:profile_changeset, Accounts.change_donor_profile(user))
  end
end
