defmodule PuenteAppWeb.Admin.DonorLive.Edit do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    donor = Accounts.get_donor_user!(id)

    form =
      %{
        "first_name" => donor.first_name,
        "last_name" => donor.last_name,
        "email" => donor.email,
        "phone" => donor.phone
      }
      |> to_form(as: "donor")

    {:noreply,
     socket
     |> assign(:page_title, "Editar donante")
     |> assign(:donor, donor)
     |> assign(:form, form)}
  rescue
    Ecto.NoResultsError ->
      {:noreply,
       socket
       |> put_flash(:error, "Donante no encontrado.")
       |> push_navigate(to: ~p"/admin/donors")}
  end

  @impl true
  def handle_event("validate", %{"donor" => params}, socket) do
    form = params |> to_form(as: "donor")
    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("save", %{"donor" => params}, socket) do
    donor = socket.assigns.donor

    case Accounts.update_donor_profile(donor, params) do
      {:ok, _updated_donor} ->
        {:noreply,
         socket
         |> put_flash(:info, "Donante actualizado correctamente.")
         |> push_navigate(to: ~p"/admin/donors")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al actualizar el donante.")}
    end
  end

  @impl true
  def handle_event("archive", _params, socket) do
    donor = socket.assigns.donor
    current_user = socket.assigns.current_scope.user

    case Accounts.archive_donor(donor, current_user.id) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Donante archivado exitosamente.")
         |> push_navigate(to: ~p"/admin/donors")}

      {:error, :invalid_role} ->
        {:noreply, put_flash(socket, :error, "El usuario no es un donante.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al archivar el donante.")}
    end
  end

  @impl true
  def handle_event("unarchive", _params, socket) do
    donor = socket.assigns.donor

    case Accounts.unarchive_donor(donor) do
      {:ok, updated_donor} ->
        {:noreply,
         socket
         |> put_flash(:info, "Donante desarchivado exitosamente.")
         |> assign(:donor, updated_donor)}

      {:error, :invalid_role} ->
        {:noreply, put_flash(socket, :error, "El usuario no es un donante.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al desarchivar el donante.")}
    end
  end
end
