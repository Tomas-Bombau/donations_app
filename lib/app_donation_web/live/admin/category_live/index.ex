defmodule AppDonationWeb.Admin.CategoryLive.Index do
  use AppDonationWeb, :live_view

  alias AppDonation.Catalog
  alias AppDonation.Catalog.Category

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    category = Catalog.get_category!(id)

    socket
    |> assign(:page_title, "Editar categoria")
    |> assign(:category, category)
    |> assign(:changeset, Catalog.change_category(category))
    |> assign(:categories, Catalog.list_categories())
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Nueva categoria")
    |> assign(:category, %Category{})
    |> assign(:changeset, Catalog.change_category(%Category{}))
    |> assign(:categories, Catalog.list_categories())
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Categorias")
    |> assign(:category, nil)
    |> assign(:changeset, nil)
    |> assign(:categories, Catalog.list_categories())
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
        {:noreply,
         socket
         |> put_flash(:info, "Categoria activada.")
         |> assign(:categories, Catalog.list_categories())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al activar la categoria.")}
    end
  end

  @impl true
  def handle_event("deactivate", %{"id" => id}, socket) do
    category = Catalog.get_category!(id)

    case Catalog.deactivate_category(category) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Categoria desactivada.")
         |> assign(:categories, Catalog.list_categories())}

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
        {:noreply, assign(socket, :changeset, changeset)}
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
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
