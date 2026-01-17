defmodule PuenteAppWeb.Organization.RequestLive.Show do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Requests

  import PuenteAppWeb.Helpers.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    request = Requests.get_request_for_organization!(id, socket.assigns.organization.id)

    {:noreply,
     socket
     |> assign(:page_title, request.title)
     |> assign(:request, request)}
  end

  @impl true
  def handle_event("publish", _params, socket) do
    case Requests.publish_request(socket.assigns.request) do
      {:ok, request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pedido publicado exitosamente.")
         |> assign(:request, Requests.get_request_for_organization!(request.id, socket.assigns.organization.id))}

      {:error, changeset} ->
        error_msg = get_error_message(changeset)
        {:noreply, put_flash(socket, :error, error_msg)}
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    case Requests.delete_request(socket.assigns.request) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Borrador eliminado.")
         |> push_navigate(to: ~p"/organization/requests")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Error al eliminar el borrador.")}
    end
  end

  @impl true
  def handle_event("complete", _params, socket) do
    case Requests.complete_request(socket.assigns.request) do
      {:ok, request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pedido finalizado.")
         |> assign(:request, Requests.get_request_for_organization!(request.id, socket.assigns.organization.id))}

      {:error, changeset} ->
        error_msg = get_error_message(changeset)
        {:noreply, put_flash(socket, :error, error_msg)}
    end
  end

  defp get_error_message(%Ecto.Changeset{} = changeset) do
    case changeset.errors[:status] do
      {msg, _} -> msg
      _ -> "Error al procesar el pedido."
    end
  end

end
