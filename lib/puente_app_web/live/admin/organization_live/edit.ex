defmodule PuenteAppWeb.Admin.OrganizationLive.Edit do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Accounts
  alias PuenteApp.Organizations.Organization
  alias PuenteAppWeb.Helpers.UploadHelpers

  import PuenteAppWeb.Helpers.FormatHelpers, only: [error_to_string: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: 5_000_000
     )}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    user = Accounts.get_user_with_profile!(id)

    user_form =
      %{"first_name" => user.first_name, "last_name" => user.last_name, "email" => user.email, "phone" => user.phone}
      |> to_form(as: "user")

    org = user.organization || %Organization{}
    org_form =
      %{
        "organization_role" => org.organization_role,
        "organization_name" => org.organization_name,
        "address" => org.address,
        "province" => org.province,
        "municipality" => org.municipality,
        "has_legal_entity" => org.has_legal_entity,
        "cbu" => org.cbu,
        "payment_alias" => org.payment_alias,
        "facebook" => org.facebook,
        "instagram" => org.instagram,
        "activities" => org.activities,
        "audience" => org.audience,
        "reach" => org.reach
      }
      |> to_form(as: "organization")

    {:noreply,
     socket
     |> assign(:page_title, "Editar organizacion")
     |> assign(:user, user)
     |> assign(:user_form, user_form)
     |> assign(:org_form, org_form)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params, "organization" => org_params}, socket) do
    # Reset municipality if province is not Buenos Aires
    org_params =
      if org_params["province"] != "Buenos Aires" do
        Map.put(org_params, "municipality", "")
      else
        org_params
      end

    user_form = user_params |> to_form(as: "user")
    org_form = org_params |> to_form(as: "organization")

    {:noreply,
     socket
     |> assign(:user_form, user_form)
     |> assign(:org_form, org_form)}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("save", %{"user" => user_params, "organization" => org_params}, socket) do
    user = socket.assigns.user

    # Handle has_legal_entity checkbox
    org_params = Map.put(org_params, "has_legal_entity", org_params["has_legal_entity"] == "true")

    # Handle image upload
    org_params = maybe_upload_image(socket, org_params, user.organization)

    case Accounts.update_organization(user, user_params, org_params) do
      {:ok, _updated_user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organizacion actualizada correctamente.")
         |> push_navigate(to: ~p"/admin/organizations")}

      {:error, changeset} ->
        errors = format_changeset_errors(changeset)
        {:noreply, put_flash(socket, :error, "Error al actualizar: #{errors}")}
    end
  end

  def handle_event("archive", _params, socket) do
    user = socket.assigns.user
    current_user = socket.assigns.current_scope.user

    case Accounts.archive_organization(user, current_user.id) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organizacion archivada exitosamente.")
         |> push_navigate(to: ~p"/admin/organizations")}

      {:error, :invalid_role} ->
        {:noreply, put_flash(socket, :error, "El usuario no es una organizacion.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al archivar la organizacion.")}
    end
  end

  def handle_event("unarchive", _params, socket) do
    user = socket.assigns.user

    case Accounts.unarchive_organization(user) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organizacion desarchivada exitosamente.")
         |> assign(:user, Accounts.get_user_with_profile!(updated_user.id))}

      {:error, :invalid_role} ->
        {:noreply, put_flash(socket, :error, "El usuario no es una organizacion.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al desarchivar la organizacion.")}
    end
  end

  defp maybe_upload_image(socket, org_params, organization) do
    case uploaded_entries(socket, :image) do
      {[_ | _], []} ->
        uploaded_files =
          consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
            with {:ok, detected_type} <- UploadHelpers.validate_magic_bytes(path),
                 true <- UploadHelpers.extension_matches_type?(entry.client_name, detected_type) do
              uploads_dir = Path.expand("./uploads/organizations")
              File.mkdir_p!(uploads_dir)

              # Generate secure UUID-based filename
              filename = UploadHelpers.generate_secure_filename(detected_type)
              dest = Path.join(uploads_dir, filename)

              # Delete old image if exists
              if organization && organization.image_path do
                old_path = Path.expand(".#{organization.image_path}")
                File.rm(old_path)
              end

              File.cp!(path, dest)
              {:ok, "/uploads/organizations/#{filename}"}
            else
              _ -> {:postpone, :invalid_file}
            end
          end)

        case uploaded_files do
          [image_path | _] when is_binary(image_path) -> Map.put(org_params, "image_path", image_path)
          _ -> org_params
        end

      _ ->
        org_params
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end
end
