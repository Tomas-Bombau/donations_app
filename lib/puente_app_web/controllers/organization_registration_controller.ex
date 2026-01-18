defmodule PuenteAppWeb.OrganizationRegistrationController do
  use PuenteAppWeb, :controller

  alias PuenteApp.Accounts
  alias PuenteApp.Accounts.User
  alias PuenteApp.Organizations
  alias PuenteApp.Organizations.Organization
  alias PuenteApp.Repo

  def new(conn, _params) do
    user_changeset = Accounts.change_user_registration(%User{})
    org_changeset = Organizations.change_organization(%Organization{})

    render(conn, :new,
      user_changeset: user_changeset,
      org_changeset: org_changeset
    )
  end

  def create(conn, %{"user" => user_params, "organization" => org_params}) do
    # Set role to requester
    user_params = Map.put(user_params, "role", "organization")

    Repo.transaction(fn ->
      with {:ok, user} <- Accounts.register_organization_user(user_params),
           org_params <- Map.put(org_params, "user_id", user.id),
           {:ok, _org} <- Organizations.register_organization(org_params) do
        user
      else
        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, user} ->
        # Send confirmation email
        Accounts.deliver_confirmation_instructions(
          user,
          &url(~p"/users/confirm/#{&1}")
        )

        conn
        |> put_flash(
          :info,
          "Te enviamos un email de confirmacion. Por favor revisa tu casilla de correo."
        )
        |> redirect(to: ~p"/")

      {:error, %Ecto.Changeset{data: %User{}} = changeset} ->
        org_changeset = Organizations.change_organization(%Organization{}, org_params)
        render(conn, :new, user_changeset: changeset, org_changeset: org_changeset)

      {:error, %Ecto.Changeset{data: %Organization{}} = changeset} ->
        user_changeset = Accounts.change_user_registration(%User{}, user_params)
        render(conn, :new, user_changeset: user_changeset, org_changeset: changeset)
    end
  end
end
