defmodule AppDonationWeb.Admin.OrganizationLive.Index do
  use AppDonationWeb, :live_view

  alias AppDonation.Accounts

  @per_page 5

  def build_pagination_path(tab, page, filters) do
    query_params =
      %{tab: tab, page: page}
      |> Map.merge(
        filters
        |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
        |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      )

    "/admin/organizations?" <> URI.encode_query(query_params)
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = params["tab"] || "pending"
    page = String.to_integer(params["page"] || "1")

    filters = %{
      "province" => params["province"] || "",
      "municipality" => params["municipality"] || "",
      "has_legal_entity" => params["has_legal_entity"] || ""
    }

    {organizations, total_count} = fetch_organizations(tab, page, filters)
    total_pages = max(1, ceil(total_count / @per_page))

    {:noreply,
     socket
     |> assign(:tab, tab)
     |> assign(:page, page)
     |> assign(:filters, filters)
     |> assign(:organizations, organizations)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters = %{
      "province" => params["province"] || "",
      "municipality" => params["municipality"] || "",
      "has_legal_entity" => params["has_legal_entity"] || ""
    }

    # Reset municipality if province is not Buenos Aires
    filters =
      if filters["province"] != "Buenos Aires" do
        Map.put(filters, "municipality", "")
      else
        filters
      end

    {:noreply, push_patch(socket, to: build_path(socket.assigns.tab, 1, filters))}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    organization = Accounts.get_user!(id)

    case Accounts.approve_user(organization) do
      {:ok, _user} ->
        {organizations, total_count} =
          fetch_organizations(socket.assigns.tab, socket.assigns.page, socket.assigns.filters)

        {:noreply,
         socket
         |> put_flash(:info, "Organizacion aprobada exitosamente.")
         |> assign(:organizations, organizations)
         |> assign(:total_count, total_count)
         |> assign(:total_pages, max(1, ceil(total_count / @per_page)))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al aprobar la organizacion.")}
    end
  end

  @impl true
  def handle_event("archive", %{"id" => id}, socket) do
    organization = Accounts.get_user!(id)
    current_user = socket.assigns.current_scope.user

    case Accounts.archive_user(organization, current_user.id) do
      {:ok, _user} ->
        {organizations, total_count} =
          fetch_organizations(socket.assigns.tab, socket.assigns.page, socket.assigns.filters)

        {:noreply,
         socket
         |> put_flash(:info, "Organizacion archivada exitosamente.")
         |> assign(:organizations, organizations)
         |> assign(:total_count, total_count)
         |> assign(:total_pages, max(1, ceil(total_count / @per_page)))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al archivar la organizacion.")}
    end
  end

  @impl true
  def handle_event("unarchive", %{"id" => id}, socket) do
    organization = Accounts.get_user!(id)

    case Accounts.unarchive_user(organization) do
      {:ok, _user} ->
        {organizations, total_count} =
          fetch_organizations(socket.assigns.tab, socket.assigns.page, socket.assigns.filters)

        {:noreply,
         socket
         |> put_flash(:info, "Organizacion desarchivada exitosamente.")
         |> assign(:organizations, organizations)
         |> assign(:total_count, total_count)
         |> assign(:total_pages, max(1, ceil(total_count / @per_page)))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al desarchivar la organizacion.")}
    end
  end

  defp fetch_organizations(tab, page, filters) do
    case tab do
      "pending" -> Accounts.list_pending_organizations_paginated(page, @per_page, filters)
      "archived" -> Accounts.list_archived_organizations_paginated(page, @per_page, filters)
      _ -> Accounts.list_approved_organizations_paginated(page, @per_page, filters)
    end
  end

  defp build_path(tab, page, filters) do
    query_params =
      %{tab: tab, page: page}
      |> Map.merge(
        filters
        |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
        |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      )

    "/admin/organizations?" <> URI.encode_query(query_params)
  end
end
