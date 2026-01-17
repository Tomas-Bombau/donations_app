defmodule PuenteAppWeb.Organization.RequestLive.Close do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Requests
  alias PuenteAppWeb.Helpers.UploadHelpers

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    request = Requests.get_request_for_organization!(id, socket.assigns.organization.id)

    if request.status != :completed do
      {:ok,
       socket
       |> put_flash(:error, "Solo se pueden cerrar pedidos finalizados.")
       |> push_navigate(to: ~p"/organization/requests/#{request}")}
    else
      changeset = Requests.change_closure(request)

      {:ok,
       socket
       |> assign(:page_title, "Publicar rendicion")
       |> assign(:request, request)
       |> assign(:form, to_form(changeset, as: "closure"))
       |> allow_upload(:images,
         accept: ~w(.jpg .jpeg .png .webp),
         max_entries: 4,
         max_file_size: 5_000_000
       )}
    end
  end

  @impl true
  def handle_event("validate", %{"closure" => params}, socket) do
    changeset =
      socket.assigns.request
      |> Requests.change_closure(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: "closure"))}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :images, ref)}
  end

  @impl true
  def handle_event("save", %{"closure" => params}, socket) do
    request = socket.assigns.request

    uploaded_images =
      consume_uploaded_entries(socket, :images, fn %{path: path}, entry ->
        with {:ok, detected_type} <- UploadHelpers.validate_magic_bytes(path),
             true <- UploadHelpers.extension_matches_type?(entry.client_name, detected_type) do
          uploads_dir = Path.expand("./uploads/requests/#{request.id}")
          File.mkdir_p!(uploads_dir)

          filename = UploadHelpers.generate_secure_filename(detected_type)
          dest = Path.join(uploads_dir, filename)

          File.cp!(path, dest)
          {:ok, "/uploads/requests/#{request.id}/#{filename}"}
        else
          _ -> {:postpone, :invalid_file}
        end
      end)

    # Filter out any invalid uploads
    valid_images = Enum.filter(uploaded_images, &is_binary/1)
    params = Map.put(params, "outcome_images", valid_images)

    case Requests.close_request(request, params) do
      {:ok, updated_request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rendicion publicada exitosamente. Gracias por tu transparencia!")
         |> push_navigate(to: ~p"/organization/requests/#{updated_request}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "closure"))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Error al publicar la rendicion.")}
    end
  end

  defp format_currency(amount) do
    amount
    |> Decimal.round(2)
    |> Decimal.to_string()
    |> then(&"$#{&1}")
  end

  defp error_to_string(:too_large), do: "Archivo muy grande (max 5MB)"
  defp error_to_string(:too_many_files), do: "Maximo 4 imagenes"
  defp error_to_string(:not_accepted), do: "Formato no soportado (solo JPG, PNG, WebP)"
  defp error_to_string(_), do: "Error al subir archivo"
end
