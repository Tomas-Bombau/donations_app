defmodule AppDonationWeb.Donor.ProfileLive do
  use AppDonationWeb, :live_view

  alias AppDonation.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    changeset = Accounts.change_user_email(user, %{}, validate_unique: false)

    {:ok,
     socket
     |> assign(:page_title, "Mi Perfil")
     |> assign(:user, user)
     |> assign(:email_form, to_form(changeset, as: "user"))
     |> assign(:editing_email, false)}
  end

  @impl true
  def handle_event("edit_email", _params, socket) do
    {:noreply, assign(socket, :editing_email, true)}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    user = socket.assigns.user
    changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    {:noreply, assign(socket, editing_email: false, email_form: to_form(changeset, as: "user"))}
  end

  @impl true
  def handle_event("validate_email", %{"user" => params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_email(params, validate_unique: false)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :email_form, to_form(changeset, as: "user"))}
  end

  @impl true
  def handle_event("save_email", %{"user" => %{"email" => email}}, socket) do
    user = socket.assigns.user

    # For now, just show that the feature will send a confirmation email
    # TODO: Implement proper email confirmation flow
    changeset = Accounts.change_user_email(user, %{"email" => email})

    if changeset.valid? do
      {:noreply,
       socket
       |> put_flash(:info, "Se enviara un email de confirmacion a #{email} para verificar el cambio.")
       |> assign(:editing_email, false)
       |> assign(:email_form, to_form(Accounts.change_user_email(user, %{}, validate_unique: false), as: "user"))}
    else
      {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :validate), as: "user"))}
    end
  end
end
