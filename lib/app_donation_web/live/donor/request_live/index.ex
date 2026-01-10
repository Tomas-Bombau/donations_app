defmodule AppDonationWeb.Donor.RequestLive.Index do
  use AppDonationWeb, :live_view

  alias AppDonation.Requests
  alias AppDonation.Catalog

  @per_page 5

  @impl true
  def mount(_params, _session, socket) do
    categories = Catalog.list_active_categories()
    {:ok, assign(socket, :categories, categories)}
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

  defp fetch_requests(page, filters) do
    Requests.list_active_requests(
      page: page,
      per_page: @per_page,
      category_id: filters["category_id"],
      province: filters["province"],
      municipality: filters["municipality"]
    )
  end

  defp build_path(page, filters) do
    query_params =
      %{page: page}
      |> Map.merge(
        filters
        |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
        |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      )

    if query_params == %{page: 1} do
      ~p"/donor/requests"
    else
      "/donor/requests?" <> URI.encode_query(query_params)
    end
  end

  def build_pagination_path(page, filters) do
    build_path(page, filters)
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
