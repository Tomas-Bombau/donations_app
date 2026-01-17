defmodule PuenteAppWeb.Admin.DonorLive.Index do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Accounts

  @per_page 5

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = params["tab"] || "active"
    page = String.to_integer(params["page"] || "1")

    filters = %{
      "search" => params["search"] || ""
    }

    {donors, total_count} = fetch_donors(tab, page, filters)
    total_pages = max(1, ceil(total_count / @per_page))

    {:noreply,
     socket
     |> assign(:tab, tab)
     |> assign(:page, page)
     |> assign(:filters, filters)
     |> assign(:donors, donors)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters = %{
      "search" => params["search"] || ""
    }

    {donors, total_count} = fetch_donors(socket.assigns.tab, 1, filters)
    total_pages = max(1, ceil(total_count / @per_page))

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:donors, donors)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)
     |> assign(:page, 1)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    filters = %{"search" => ""}

    {donors, total_count} = fetch_donors(socket.assigns.tab, 1, filters)
    total_pages = max(1, ceil(total_count / @per_page))

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:donors, donors)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)
     |> assign(:page, 1)}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    page = String.to_integer(page)
    {donors, total_count} = fetch_donors(socket.assigns.tab, page, socket.assigns.filters)

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:donors, donors)
     |> assign(:total_count, total_count)}
  end

  @impl true
  def handle_event("archive", %{"id" => id}, socket) do
    donor = Accounts.get_donor_user!(id)
    current_user = socket.assigns.current_scope.user

    case Accounts.archive_donor(donor, current_user.id) do
      {:ok, _user} ->
        {donors, total_count} = fetch_donors(socket.assigns.tab, socket.assigns.page, socket.assigns.filters)

        {:noreply,
         socket
         |> put_flash(:info, "Donante archivado exitosamente.")
         |> assign(:donors, donors)
         |> assign(:total_count, total_count)
         |> assign(:total_pages, max(1, ceil(total_count / @per_page)))}

      {:error, :invalid_role} ->
        {:noreply, put_flash(socket, :error, "El usuario no es un donante.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al archivar el donante.")}
    end
  rescue
    Ecto.NoResultsError ->
      {:noreply, put_flash(socket, :error, "Donante no encontrado.")}
  end

  @impl true
  def handle_event("unarchive", %{"id" => id}, socket) do
    donor = Accounts.get_donor_user!(id)

    case Accounts.unarchive_donor(donor) do
      {:ok, _user} ->
        {donors, total_count} = fetch_donors(socket.assigns.tab, socket.assigns.page, socket.assigns.filters)

        {:noreply,
         socket
         |> put_flash(:info, "Donante desarchivado exitosamente.")
         |> assign(:donors, donors)
         |> assign(:total_count, total_count)
         |> assign(:total_pages, max(1, ceil(total_count / @per_page)))}

      {:error, :invalid_role} ->
        {:noreply, put_flash(socket, :error, "El usuario no es un donante.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al desarchivar el donante.")}
    end
  rescue
    Ecto.NoResultsError ->
      {:noreply, put_flash(socket, :error, "Donante no encontrado.")}
  end

  defp fetch_donors(tab, page, filters) do
    case tab do
      "archived" -> Accounts.list_archived_users_by_role_paginated(:donor, page, @per_page, filters)
      _ -> Accounts.list_users_by_role_paginated(:donor, page, @per_page, filters)
    end
  end
end
