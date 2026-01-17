defmodule PuenteAppWeb.Organization.RequestLive.Index do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Requests
  alias PuenteApp.Organizations.Organization

  @per_page 5

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    organization = socket.assigns.organization
    page = String.to_integer(params["page"] || "1")

    # Determine default status based on organization's requests
    status = params["status"] || default_status(organization.id)

    {requests, total_count} = Requests.list_requests_for_organization(
      organization.id,
      status: status,
      page: page,
      per_page: @per_page
    )

    total_pages = ceil(total_count / @per_page)

    can_create = cond do
      not Organization.has_payment_configured?(organization) ->
        {:no, "Comunicate con un administrador para configurar tu CBU o alias"}

      Requests.has_active_request?(organization.id) ->
        {:no, "Ya tienes un pedido activo"}

      Requests.has_pending_closure?(organization.id) ->
        {:no, "Tienes un pedido finalizado pendiente de rendición"}

      true ->
        :yes
    end

    {:noreply,
     socket
     |> assign(:page_title, "Mis pedidos")
     |> assign(:status, status)
     |> assign(:requests, requests)
     |> assign(:page, page)
     |> assign(:total_pages, total_pages)
     |> assign(:total_count, total_count)
     |> assign(:can_create, can_create)}
  end

  defp default_status(organization_id) do
    cond do
      Requests.has_pending_closure?(organization_id) -> "completed"
      Requests.has_active_request?(organization_id) -> "active"
      true -> "draft"
    end
  end

  defp status_badge(status) do
    case status do
      :draft -> "badge-warning"
      :active -> "badge-success"
      :completed -> "badge-error"
      :closed -> "badge-info"
    end
  end

  defp status_label(status) do
    case status do
      :draft -> "Borrador"
      :active -> "Activo"
      :completed -> "Finalizado"
      :closed -> "Cerrado"
    end
  end

  defp format_currency(amount) do
    amount
    |> Decimal.round(2)
    |> Decimal.to_string()
    |> then(&"$#{&1}")
  end

  defp format_date(date) do
    Calendar.strftime(date, "%d/%m/%Y")
  end

  defp build_path(status, page) do
    params = %{}
    params = if status != "draft", do: Map.put(params, "status", status), else: params
    params = if page > 1, do: Map.put(params, "page", page), else: params

    if params == %{} do
      ~p"/organization/requests"
    else
      ~p"/organization/requests?#{params}"
    end
  end
end
