defmodule AppDonationWeb.Organization.ProfileLive do
  use AppDonationWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    organization = socket.assigns.organization
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:page_title, "Mi Perfil")
     |> assign(:user, user)
     |> assign(:organization, organization)}
  end
end
