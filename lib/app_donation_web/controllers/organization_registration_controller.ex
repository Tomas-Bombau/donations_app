defmodule AppDonationWeb.OrganizationRegistrationController do
  use AppDonationWeb, :controller

  alias AppDonation.Accounts
  alias AppDonation.Accounts.User
  alias AppDonation.Organizations
  alias AppDonation.Organizations.Organization
  alias AppDonation.Repo

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
      with {:ok, user} <- Accounts.register_user(user_params),
           org_params <- Map.put(org_params, "user_id", user.id),
           {:ok, _org} <- Organizations.create_organization(org_params) do
        user
      else
        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, _user} ->
        conn
        |> put_flash(
          :info,
          "Tu solicitud fue enviada. Un administrador revisara tu cuenta y te notificaremos por email cuando sea aprobada."
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
