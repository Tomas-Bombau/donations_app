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
    status = params["status"] || "all"
    page = String.to_integer(params["page"] || "1")
    organization = socket.assigns.organization

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

      not Requests.can_create_new_request?(organization.id) ->
        {:no, "Espera 2 semanas desde tu ultimo pedido"}

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

  defp status_badge(status) do
    case status do
      :draft -> "badge-warning"
      :active -> "badge-success"
      :completed -> "badge-error"
    end
  end

  defp status_label(status) do
    case status do
      :draft -> "Borrador"
      :active -> "Activo"
      :completed -> "Finalizado"
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
    params = if status != "all", do: Map.put(params, "status", status), else: params
    params = if page > 1, do: Map.put(params, "page", page), else: params

    if params == %{} do
      ~p"/organization/requests"
    else
      ~p"/organization/requests?#{params}"
    end
  end
end
