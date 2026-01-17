defmodule PuenteAppWeb.Donor.RequestLive.Index do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Requests
  alias PuenteApp.Catalog
  alias PuenteApp.Donations
  alias PuenteApp.Donations.Donation

  import PuenteAppWeb.Helpers.FormatHelpers, only: [format_currency: 1]

  @per_page 5

  @impl true
  def mount(_params, _session, socket) do
    categories = Catalog.list_active_categories()
    changeset = Donations.change_donation(%Donation{}, %{})

    {:ok,
     socket
     |> assign(:categories, categories)
     |> assign(:show_modal, false)
     |> assign(:selected_request, nil)
     |> assign(:form, to_form(changeset, as: "donation"))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = String.to_integer(params["page"] || "1")

    filters = %{
      "province" => params["province"] || "",
      "municipality" => params["municipality"] || "",
      "category_id" => params["category_id"] || ""
    }

    {requests, total_count} = fetch_requests(page, filters)
    total_pages = max(1, ceil(total_count / @per_page))

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:filters, filters)
     |> assign(:requests, requests)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)
     |> assign(:page_title, "Pedidos activos")}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters = %{
      "province" => params["province"] || "",
      "municipality" => params["municipality"] || "",
      "category_id" => params["category_id"] || ""
    }

    # Reset municipality if province changes
    filters =
      if filters["province"] != "Buenos Aires" do
        Map.put(filters, "municipality", "")
      else
        filters
      end

    {:noreply, push_patch(socket, to: build_path(1, filters))}
  end

  @impl true
  def handle_event("open_modal", %{"id" => id}, socket) do
    request = Requests.get_request!(id)
    {:noreply, assign(socket, show_modal: true, selected_request: request)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    changeset = Donations.change_donation(%Donation{}, %{})
    {:noreply, assign(socket, show_modal: false, selected_request: nil, form: to_form(changeset, as: "donation"))}
  end

  @impl true
  def handle_event("validate_donation", %{"donation" => params}, socket) do
    changeset =
      %Donation{}
      |> Donations.change_donation(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: "donation"))}
  end

  @impl true
  def handle_event("save_donation", %{"donation" => params}, socket) do
    user = socket.assigns.current_scope.user
    request = socket.assigns.selected_request

    attrs = %{
      "donor_id" => user.id,
      "request_id" => request.id,
      "amount" => params["amount"]
    }

    case Donations.create_donation(attrs) do
      {:ok, _donation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Donacion registrada exitosamente. Gracias por tu aporte!")
         |> assign(:show_modal, false)
         |> push_navigate(to: ~p"/donor/donations")}

      {:error, :request_not_active} ->
        {:noreply,
         socket
         |> put_flash(:error, "Este pedido ya no esta activo.")
         |> assign(:show_modal, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "donation"))}
    end
  end

  defp fetch_requests(page, filters) do
    Requests.list_active_requests(
      page: page,
      per_page: @per_page,
      category_id: filters["category_id"],
      province: filters["province"],
      municipality: filters["municipality"]
    )
  end

  # Allowed filter keys to prevent atom injection attacks
  @allowed_filter_keys ~w(province municipality category_id)

  defp build_path(page, filters) do
    # Only allow known filter keys (whitelist approach)
    safe_filters =
      filters
      |> Enum.filter(fn {k, v} -> k in @allowed_filter_keys and v != "" and not is_nil(v) end)
      |> Map.new()

    query_params = Map.put(safe_filters, "page", page)

    if query_params == %{"page" => 1} do
      ~p"/donor/requests"
    else
      "/donor/requests?" <> URI.encode_query(query_params)
    end
  end

  defp build_pagination_path(page, filters) do
    build_path(page, filters)
  end

  defp days_until_deadline(deadline) do
    days = Date.diff(deadline, Date.utc_today())

    cond do
      days < 0 -> "Vencido"
      days == 0 -> "Vence hoy"
      days == 1 -> "Vence manana"
      true -> "Vence en #{days} dias"
    end
  end

  defp progress_percentage(amount_raised, amount) do
    if Decimal.compare(amount, Decimal.new(0)) == :gt do
      amount_raised
      |> Decimal.div(amount)
      |> Decimal.mult(100)
      |> Decimal.round(0)
      |> Decimal.to_integer()
      |> min(100)
    else
      0
    end
  end
end
