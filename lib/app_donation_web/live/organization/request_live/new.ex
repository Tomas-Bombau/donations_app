defmodule AppDonationWeb.Organization.RequestLive.New do
  use AppDonationWeb, :live_view

  alias AppDonation.Requests
  alias AppDonation.Requests.Request
  alias AppDonation.Catalog
  alias AppDonation.Organizations.Organization

  @impl true
  def mount(_params, _session, socket) do
    organization = socket.assigns.organization

    cond do
      not Organization.has_payment_configured?(organization) ->
        {:ok,
         socket
         |> put_flash(:error, "Debes configurar un CBU o alias antes de crear pedidos.")
         |> push_navigate(to: ~p"/organization/profile")}

      Requests.has_active_request?(organization.id) ->
        {:ok,
         socket
         |> put_flash(:error, "Ya tienes un pedido activo. Finaliza el actual antes de crear uno nuevo.")
         |> push_navigate(to: ~p"/organization/requests")}

      not Requests.can_create_new_request?(organization.id) ->
        {:ok,
         socket
         |> put_flash(:error, "Debes esperar al menos 2 semanas desde tu ultimo pedido para crear uno nuevo.")
         |> push_navigate(to: ~p"/organization/requests")}

      true ->
        changeset = Requests.change_request(%Request{})
        categories = Catalog.list_active_categories()

        {:ok,
         socket
         |> assign(:page_title, "Nuevo pedido")
         |> assign(:form, to_form(changeset, as: "request"))
         |> assign(:categories, categories)
         |> assign(:reference_links, [])}
    end
  end

  @impl true
  def handle_event("validate", %{"request" => params}, socket) do
    params = put_reference_links(params, socket.assigns.reference_links)
    params = Map.put(params, "organization_id", socket.assigns.organization.id)

    changeset =
      %Request{}
      |> Requests.change_request(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: "request"))}
  end

  @impl true
  def handle_event("save", %{"request" => params}, socket) do
    params = put_reference_links(params, socket.assigns.reference_links)

    case Requests.create_request(socket.assigns.organization, params) do
      {:ok, request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pedido creado como borrador.")
         |> push_navigate(to: ~p"/organization/requests/#{request}")}

      {:error, :payment_not_configured} ->
        {:noreply,
         socket
         |> put_flash(:error, "Debes configurar un CBU o alias antes de crear pedidos.")
         |> push_navigate(to: ~p"/organization/profile")}

      {:error, :has_active_request} ->
        {:noreply,
         socket
         |> put_flash(:error, "Ya tienes un pedido activo. Finaliza el actual antes de crear uno nuevo.")
         |> push_navigate(to: ~p"/organization/requests")}

      {:error, :too_soon} ->
        {:noreply,
         socket
         |> put_flash(:error, "Debes esperar al menos 2 semanas desde tu ultimo pedido para crear uno nuevo.")
         |> push_navigate(to: ~p"/organization/requests")}

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
