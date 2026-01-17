defmodule PuenteAppWeb.Admin.CategoryLive.Index do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Catalog
  alias PuenteApp.Catalog.Category

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = String.to_integer(params["page"] || "1")
    filters = %{"search" => params["search"] || ""}

    {:noreply, apply_action(socket, socket.assigns.live_action, params, page, filters)}
  end

  defp apply_action(socket, :edit, %{"id" => id}, page, filters) do
    category = Catalog.get_category!(id)
    {categories, total_count} = Catalog.list_categories_paginated(page, @per_page, filters)
    total_pages = max(1, ceil(total_count / @per_page))

    socket
    |> assign(:page_title, "Editar categoria")
    |> assign(:category, category)
    |> assign(:form, to_form(Catalog.change_category(category)))
    |> assign(:categories, categories)
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:filters, filters)
  end

  defp apply_action(socket, :new, _params, page, filters) do
    {categories, total_count} = Catalog.list_categories_paginated(page, @per_page, filters)
    total_pages = max(1, ceil(total_count / @per_page))

    socket
    |> assign(:page_title, "Nueva categoria")
    |> assign(:category, %Category{})
    |> assign(:form, to_form(Catalog.change_category(%Category{})))
    |> assign(:categories, categories)
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:filters, filters)
  end

  defp apply_action(socket, :index, _params, page, filters) do
    {categories, total_count} = Catalog.list_categories_paginated(page, @per_page, filters)
    total_pages = max(1, ceil(total_count / @per_page))

    socket
    |> assign(:page_title, "Categorias")
    |> assign(:category, nil)
    |> assign(:form, nil)
    |> assign(:categories, categories)
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:filters, filters)
  end

  @impl true
  def handle_event("filter", %{"search" => search}, socket) do
    filters = %{"search" => search}
    {categories, total_count} = Catalog.list_categories_paginated(1, @per_page, filters)
    total_pages = max(1, ceil(total_count / @per_page))

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:categories, categories)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)
     |> assign(:page, 1)}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    page = String.to_integer(page)
    {categories, total_count} = Catalog.list_categories_paginated(page, @per_page, socket.assigns.filters)

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:categories, categories)
     |> assign(:total_count, total_count)}
  end

  @impl true
  def handle_event("save", %{"category" => category_params}, socket) do
    save_category(socket, socket.assigns.live_action, category_params)
  end

  @impl true
  def handle_event("activate", %{"id" => id}, socket) do
    category = Catalog.get_category!(id)

    case Catalog.activate_category(category) do
      {:ok, _category} ->
        {categories, total_count} =
          Catalog.list_categories_paginated(socket.assigns.page, @per_page, socket.assigns.filters)

        {:noreply,
         socket
         |> put_flash(:info, "Categoria activada.")
         |> assign(:categories, categories)
         |> assign(:total_count, total_count)
         |> assign(:total_pages, max(1, ceil(total_count / @per_page)))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al activar la categoria.")}
    end
  end

  @impl true
  def handle_event("deactivate", %{"id" => id}, socket) do
    category = Catalog.get_category!(id)

    case Catalog.deactivate_category(category) do
      {:ok, _category} ->
        {categories, total_count} =
          Catalog.list_categories_paginated(socket.assigns.page, @per_page, socket.assigns.filters)

        {:noreply,
         socket
         |> put_flash(:info, "Categoria desactivada.")
         |> assign(:categories, categories)
         |> assign(:total_count, total_count)
         |> assign(:total_pages, max(1, ceil(total_count / @per_page)))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al desactivar la categoria.")}
    end
  end

  defp save_category(socket, :edit, category_params) do
    case Catalog.update_category(socket.assigns.category, category_params) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Categoria actualizada.")
         |> push_patch(to: ~p"/admin/categories")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_category(socket, :new, category_params) do
    case Catalog.create_category(category_params) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Categoria creada.")
         |> push_patch(to: ~p"/admin/categories")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
