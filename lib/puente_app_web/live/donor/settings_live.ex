defmodule PuenteAppWeb.Donor.SettingsLive do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Accounts
  alias PuenteAppWeb.Helpers.UploadHelpers

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    profile_changeset = Accounts.change_donor_profile(user)
    password_changeset = Accounts.change_user_password(user)

    {:ok,
     socket
     |> assign(:page_title, "Configuracion")
     |> assign(:user, user)
     |> assign(:profile_form, to_form(profile_changeset))
     |> assign(:password_form, to_form(password_changeset))
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: 5_000_000
     )}
  end

  @impl true
  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_donor_profile(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :profile_form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate_password", %{"user" => password_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_password(password_params, hash_password: false)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :password_form, to_form(changeset))}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  @impl true
  def handle_event("save_profile", %{"user" => user_params}, socket) do
    user = socket.assigns.user
    user_params = maybe_upload_image(socket, user_params, user)

    case Accounts.update_donor_profile(user, user_params) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:user, updated_user)
         |> assign(:profile_form, to_form(Accounts.change_donor_profile(updated_user)))
         |> put_flash(:info, "Perfil actualizado correctamente.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("save_password", %{"user" => password_params}, socket) do
    user = socket.assigns.user

    case Accounts.update_user_password(user, password_params) do
      {:ok, {_user, _}} ->
        {:noreply,
         socket
         |> put_flash(:info, "Contrasena actualizada correctamente. Por favor, inicia sesion nuevamente.")
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, changeset} ->
        {:noreply, assign(socket, :password_form, to_form(changeset))}
    end
  end

  defp maybe_upload_image(socket, user_params, user) do
    case uploaded_entries(socket, :image) do
      {[_ | _], []} ->
        uploaded_files =
          consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
            with {:ok, detected_type} <- UploadHelpers.validate_magic_bytes(path),
                 true <- UploadHelpers.extension_matches_type?(entry.client_name, detected_type) do
              uploads_dir = Path.expand("./uploads/users")
              File.mkdir_p!(uploads_dir)

              # Generate secure UUID-based filename
              filename = UploadHelpers.generate_secure_filename(detected_type)
              dest = Path.join(uploads_dir, filename)

              # Delete old image if exists
              if user.image_path do
                old_path = Path.expand(".#{user.image_path}")
                File.rm(old_path)
              end

              File.cp!(path, dest)
              {:ok, "/uploads/users/#{filename}"}
            else
              _ -> {:postpone, :invalid_file}
            end
          end)

        case uploaded_files do
          [image_path | _] when is_binary(image_path) -> Map.put(user_params, "image_path", image_path)
          _ -> user_params
        end

      _ ->
        user_params
    end
  end

  defp error_to_string(:too_large), do: "El archivo es muy grande (max 5MB)"
  defp error_to_string(:not_accepted), do: "Tipo de archivo no permitido. Solo JPG, PNG o WebP"
  defp error_to_string(:too_many_files), do: "Solo se permite un archivo"
  defp error_to_string(_), do: "Error al subir el archivo"
end
