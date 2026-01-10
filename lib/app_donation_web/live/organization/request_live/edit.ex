defmodule AppDonationWeb.Organization.RequestLive.Edit do
  use AppDonationWeb, :live_view

  alias AppDonation.Requests
  alias AppDonation.Catalog

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    request = Requests.get_request_for_organization!(id, socket.assigns.organization.id)

    if request.status == :draft do
      changeset = Requests.change_request(request)
      categories = Catalog.list_active_categories()

      {:ok,
       socket
       |> assign(:page_title, "Editar pedido")
       |> assign(:request, request)
       |> assign(:form, to_form(changeset, as: "request"))
       |> assign(:categories, categories)
       |> assign(:reference_links, request.reference_links || [])}
    else
      {:ok,
       socket
       |> put_flash(:error, "Solo se pueden editar pedidos en borrador.")
       |> push_navigate(to: ~p"/organization/requests/#{request}")}
    end
  end

  @impl true
  def handle_event("validate", %{"request" => params}, socket) do
    params = put_reference_links(params, socket.assigns.reference_links)

    changeset =
      socket.assigns.request
      |> Requests.change_request(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: "request"))}
  end

  @impl true
  def handle_event("save", %{"request" => params}, socket) do
    params = put_reference_links(params, socket.assigns.reference_links)

    case Requests.update_request(socket.assigns.request, params) do
      {:ok, request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pedido actualizado.")
         |> push_navigate(to: ~p"/organization/requests/#{request}")}

      {:error, :cannot_update_published} ->
        {:noreply,
         socket
         |> put_flash(:error, "Solo se pueden editar pedidos en borrador.")
         |> push_navigate(to: ~p"/organization/requests/#{socket.assigns.request}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "request"))}
    end
  end

  @impl true
  def handle_event("add_link", _params, socket) do
    {:noreply, assign(socket, :reference_links, socket.assigns.reference_links ++ [""])}
  end

  @impl true
  def handle_event("remove_link", %{"index" => index}, socket) do
    index = String.to_integer(index)
    links = List.delete_at(socket.assigns.reference_links, index)
    {:noreply, assign(socket, :reference_links, links)}
  end

  @impl true
  def handle_event("update_link", %{"index" => index, "value" => value}, socket) do
    index = String.to_integer(index)
    links = List.replace_at(socket.assigns.reference_links, index, value)
    {:noreply, assign(socket, :reference_links, links)}
  end

  defp put_reference_links(params, links) do
    links = Enum.filter(links, &(&1 != ""))
    Map.put(params, "reference_links", links)
  end
end
