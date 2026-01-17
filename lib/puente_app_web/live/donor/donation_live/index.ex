defmodule PuenteAppWeb.Donor.DonationLive.Index do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Donations
  alias PuenteApp.Requests

  @per_page 5

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, show_closure: false, closure_request: nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = String.to_integer(params["page"] || "1")
    user = socket.assigns.current_scope.user

    {donations, total_count} = Donations.list_donations_for_donor(user.id, page: page, per_page: @per_page)
    total_pages = max(1, ceil(total_count / @per_page))

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:donations, donations)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)
     |> assign(:page_title, "Mis donaciones")}
  end

  @impl true
  def handle_event("show_closure", %{"id" => request_id}, socket) do
    request = Requests.get_request!(request_id)
    {:noreply, assign(socket, show_closure: true, closure_request: request)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_closure: false, closure_request: nil)}
  end

  def build_pagination_path(page) do
    if page == 1 do
      ~p"/donor/donations"
    else
      "/donor/donations?" <> URI.encode_query(%{page: page})
    end
  end

  defp format_currency(amount) do
    amount
    |> Decimal.round(2)
    |> Decimal.to_string()
    |> then(&"$#{&1}")
  end

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%d/%m/%Y")
  end

  defp request_status_badge(status) do
    case status do
      :draft -> "badge-ghost"
      :active -> "badge-warning"
      :completed -> "badge-error"
      :closed -> "badge-success"
    end
  end

  defp request_status_label(status) do
    case status do
      :draft -> "Borrador"
      :active -> "En curso"
      :completed -> "Pendiente de rendicion"
      :closed -> "Rendicion disponible"
    end
  end
end
