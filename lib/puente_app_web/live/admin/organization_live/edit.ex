defmodule PuenteAppWeb.Admin.OrganizationLive.Edit do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Accounts
  alias PuenteApp.Organizations.Organization

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

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  @impl true
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

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al actualizar la organizacion.")}
    end
  end

  defp maybe_upload_image(socket, org_params, organization) do
    case uploaded_entries(socket, :image) do
      {[_ | _], []} ->
        # There are completed uploads
        uploaded_files =
          consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
            # Ensure uploads directory exists
            uploads_dir = Path.expand("./uploads/organizations")
            File.mkdir_p!(uploads_dir)

            # Generate unique filename using organization id
            ext = Path.extname(entry.client_name)
            filename = "#{organization.id}#{ext}"
            dest = Path.join(uploads_dir, filename)

            # Copy the file
            File.cp!(path, dest)

            {:ok, "/uploads/organizations/#{filename}"}
          end)

        case uploaded_files do
          [image_path | _] -> Map.put(org_params, "image_path", image_path)
          _ -> org_params
        end

      _ ->
        org_params
    end
  end

  defp error_to_string(:too_large), do: "El archivo es muy grande (max 5MB)"
  defp error_to_string(:not_accepted), do: "Tipo de archivo no permitido. Solo JPG, PNG o WebP"
  defp error_to_string(:too_many_files), do: "Solo se permite un archivo"
  defp error_to_string(_), do: "Error al subir el archivo"
end
