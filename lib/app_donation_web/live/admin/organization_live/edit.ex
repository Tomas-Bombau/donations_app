defmodule AppDonationWeb.Admin.OrganizationLive.Edit do
  use AppDonationWeb, :live_view

  alias AppDonation.Accounts
  alias AppDonation.Organizations.Organization

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    user = Accounts.get_user_with_profile!(id)

    user_form =
      %{"first_name" => user.first_name, "last_name" => user.last_name, "email" => user.email, "phone" => user.phone}
      |> to_form(as: "user")

    org = user.organization || %Organization{}
    org_form =
      %{
        "organization_role" => org.organization_role,
        "organization_name" => org.organization_name,
        "address" => org.address,
        "province" => org.province,
        "municipality" => org.municipality,
        "has_legal_entity" => org.has_legal_entity,
        "cbu" => org.cbu,
        "payment_alias" => org.payment_alias
      }
      |> to_form(as: "organization")

    {:noreply,
     socket
     |> assign(:page_title, "Editar organizacion")
     |> assign(:user, user)
     |> assign(:user_form, user_form)
     |> assign(:org_form, org_form)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params, "organization" => org_params}, socket) do
    # Reset municipality if province is not Buenos Aires
    org_params =
      if org_params["province"] != "Buenos Aires" do
        Map.put(org_params, "municipality", "")
      else
        org_params
      end

    user_form = user_params |> to_form(as: "user")
    org_form = org_params |> to_form(as: "organization")

    {:noreply,
     socket
     |> assign(:user_form, user_form)
     |> assign(:org_form, org_form)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params, "organization" => org_params}, socket) do
    user = socket.assigns.user

    # Handle has_legal_entity checkbox
    org_params = Map.put(org_params, "has_legal_entity", org_params["has_legal_entity"] == "true")

    case Accounts.update_organization(user, user_params, org_params) do
      {:ok, _updated_user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organizacion actualizada correctamente.")
         |> push_navigate(to: ~p"/admin/organizations")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al actualizar la organizacion.")}
    end
  end
end
