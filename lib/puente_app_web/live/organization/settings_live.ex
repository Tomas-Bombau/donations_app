defmodule PuenteAppWeb.Organization.SettingsLive do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Accounts
  alias PuenteApp.Organizations

  @impl true
  def mount(_params, _session, socket) do
    organization = socket.assigns.organization
    user = socket.assigns.current_scope.user

    user_changeset = Accounts.change_donor_profile(user)
    org_changeset = Organizations.change_organization_social(organization)

    {:ok,
     socket
     |> assign(:page_title, "Configuracion")
     |> assign(:user, user)
     |> assign(:organization, organization)
     |> assign(:user_form, to_form(user_changeset))
     |> assign(:org_form, to_form(org_changeset))}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params} = params, socket) do
    user = socket.assigns.user
    organization = socket.assigns.organization
    org_params = params["organization"] || %{}

    user_changeset =
      user
      |> Accounts.change_donor_profile(user_params)
      |> Map.put(:action, :validate)

    org_changeset =
      organization
      |> Organizations.change_organization_social(org_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:user_form, to_form(user_changeset))
     |> assign(:org_form, to_form(org_changeset))}
  end

  @impl true
  def handle_event("save", %{"user" => user_params} = params, socket) do
    user = socket.assigns.user
    organization = socket.assigns.organization
    org_params = params["organization"] || %{}

    # Only allow editing specific fields for organization
    org_params = Map.take(org_params, ["facebook", "instagram"])

    with {:ok, updated_user} <- Accounts.update_donor_profile(user, user_params),
         {:ok, updated_org} <- Organizations.update_organization_social(organization, org_params) do
      {:noreply,
       socket
       |> assign(:user, updated_user)
       |> assign(:organization, updated_org)
       |> assign(:user_form, to_form(Accounts.change_donor_profile(updated_user)))
       |> assign(:org_form, to_form(Organizations.change_organization_social(updated_org)))
       |> put_flash(:info, "Configuracion actualizada correctamente")}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:user_form, to_form(changeset))
         |> put_flash(:error, "Error al actualizar la configuracion")}
    end
  end
end
