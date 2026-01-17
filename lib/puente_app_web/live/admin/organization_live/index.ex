defmodule PuenteAppWeb.Admin.OrganizationLive.Index do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Accounts

  @per_page 5

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
      "has_legal_entity" => params["has_legal_entity"] || "",
      "search" => params["search"] || ""
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
      "has_legal_entity" => params["has_legal_entity"] || "",
      "search" => params["search"] || ""
    }

    # Reset municipality if province is not Buenos Aires
    filters =
      if filters["province"] != "Buenos Aires" do
        Map.put(filters, "municipality", "")
      else
        filters
      end

    {organizations, total_count} = fetch_organizations(socket.assigns.tab, 1, filters)
    total_pages = max(1, ceil(total_count / @per_page))

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:organizations, organizations)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)
     |> assign(:page, 1)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    filters = %{
      "province" => "",
      "municipality" => "",
      "has_legal_entity" => "",
      "search" => ""
    }

    {organizations, total_count} = fetch_organizations(socket.assigns.tab, 1, filters)
    total_pages = max(1, ceil(total_count / @per_page))

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:organizations, organizations)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)
     |> assign(:page, 1)}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    page = String.to_integer(page)
    {organizations, total_count} = fetch_organizations(socket.assigns.tab, page, socket.assigns.filters)

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:organizations, organizations)
     |> assign(:total_count, total_count)}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    organization = Accounts.get_organization_user!(id)

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

      {:error, :invalid_role} ->
        {:noreply, put_flash(socket, :error, "El usuario no es una organizacion.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al aprobar la organizacion.")}
    end
  rescue
    Ecto.NoResultsError ->
      {:noreply, put_flash(socket, :error, "Organizacion no encontrada.")}
  end

  @impl true
  def handle_event("archive", %{"id" => id}, socket) do
    organization = Accounts.get_organization_user!(id)
    current_user = socket.assigns.current_scope.user

    case Accounts.archive_organization(organization, current_user.id) do
      {:ok, _user} ->
        {organizations, total_count} =
          fetch_organizations(socket.assigns.tab, socket.assigns.page, socket.assigns.filters)

        {:noreply,
         socket
         |> put_flash(:info, "Organizacion archivada exitosamente.")
         |> assign(:organizations, organizations)
         |> assign(:total_count, total_count)
         |> assign(:total_pages, max(1, ceil(total_count / @per_page)))}

      {:error, :invalid_role} ->
        {:noreply, put_flash(socket, :error, "El usuario no es una organizacion.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al archivar la organizacion.")}
    end
  rescue
    Ecto.NoResultsError ->
      {:noreply, put_flash(socket, :error, "Organizacion no encontrada.")}
  end

  @impl true
  def handle_event("unarchive", %{"id" => id}, socket) do
    organization = Accounts.get_organization_user!(id)

    case Accounts.unarchive_organization(organization) do
      {:ok, _user} ->
        {organizations, total_count} =
          fetch_organizations(socket.assigns.tab, socket.assigns.page, socket.assigns.filters)

        {:noreply,
         socket
         |> put_flash(:info, "Organizacion desarchivada exitosamente.")
         |> assign(:organizations, organizations)
         |> assign(:total_count, total_count)
         |> assign(:total_pages, max(1, ceil(total_count / @per_page)))}

      {:error, :invalid_role} ->
        {:noreply, put_flash(socket, :error, "El usuario no es una organizacion.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al desarchivar la organizacion.")}
    end
  rescue
    Ecto.NoResultsError ->
      {:noreply, put_flash(socket, :error, "Organizacion no encontrada.")}
  end

  defp fetch_organizations(tab, page, filters) do
    case tab do
      "pending" -> Accounts.list_pending_organizations_paginated(page, @per_page, filters)
      "archived" -> Accounts.list_archived_organizations_paginated(page, @per_page, filters)
      _ -> Accounts.list_approved_organizations_paginated(page, @per_page, filters)
    end
  end
end
