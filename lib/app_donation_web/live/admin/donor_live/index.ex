defmodule AppDonationWeb.Admin.DonorLive.Index do
  use AppDonationWeb, :live_view

  alias AppDonation.Accounts

  @per_page 5

  def build_pagination_path(tab, page) do
    "/admin/donors?" <> URI.encode_query(%{tab: tab, page: page})
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = params["tab"] || "active"
    page = String.to_integer(params["page"] || "1")

    {donors, total_count} = fetch_donors(tab, page)
    total_pages = max(1, ceil(total_count / @per_page))

    {:noreply,
     socket
     |> assign(:tab, tab)
     |> assign(:page, page)
     |> assign(:donors, donors)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)}
  end

  @impl true
  def handle_event("archive", %{"id" => id}, socket) do
    donor = Accounts.get_user!(id)
    current_user = socket.assigns.current_scope.user

    case Accounts.archive_user(donor, current_user.id) do
      {:ok, _user} ->
        {donors, total_count} = fetch_donors(socket.assigns.tab, socket.assigns.page)

        {:noreply,
         socket
         |> put_flash(:info, "Donante archivado exitosamente.")
         |> assign(:donors, donors)
         |> assign(:total_count, total_count)
         |> assign(:total_pages, max(1, ceil(total_count / @per_page)))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al archivar el donante.")}
    end
  end

  @impl true
  def handle_event("unarchive", %{"id" => id}, socket) do
    donor = Accounts.get_user!(id)

    case Accounts.unarchive_user(donor) do
      {:ok, _user} ->
        {donors, total_count} = fetch_donors(socket.assigns.tab, socket.assigns.page)

        {:noreply,
         socket
         |> put_flash(:info, "Donante desarchivado exitosamente.")
         |> assign(:donors, donors)
         |> assign(:total_count, total_count)
         |> assign(:total_pages, max(1, ceil(total_count / @per_page)))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al desarchivar el donante.")}
    end
  end

  defp fetch_donors(tab, page) do
    case tab do
      "archived" -> Accounts.list_archived_users_by_role_paginated(:donor, page, @per_page)
      _ -> Accounts.list_users_by_role_paginated(:donor, page, @per_page)
    end
  end
end
