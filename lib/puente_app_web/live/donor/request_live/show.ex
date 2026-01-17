defmodule PuenteAppWeb.Donor.RequestLive.Show do
  use PuenteAppWeb, :live_view

  alias PuenteApp.Requests
  alias PuenteApp.Donations
  alias PuenteApp.Donations.Donation

  import PuenteAppWeb.Helpers.FormatHelpers, only: [format_currency: 1, format_date: 1]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    request = Requests.get_request!(id)

    # Ensure request is active
    if request.status != :active do
      {:ok,
       socket
       |> put_flash(:error, "Este pedido no esta activo.")
       |> push_navigate(to: ~p"/donor/requests")}
    else
      changeset = Donations.change_donation(%Donation{}, %{})

      {:ok,
       socket
       |> assign(:request, request)
       |> assign(:page_title, request.title)
       |> assign(:show_modal, false)
       |> assign(:form, to_form(changeset, as: "donation"))}
    end
  end

  @impl true
  def handle_event("open_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    changeset = Donations.change_donation(%Donation{}, %{})
    {:noreply, assign(socket, show_modal: false, form: to_form(changeset, as: "donation"))}
  end

  @impl true
  def handle_event("validate_donation", %{"donation" => params}, socket) do
    changeset =
      %Donation{}
      |> Donations.change_donation(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: "donation"))}
  end

  @impl true
  def handle_event("save_donation", %{"donation" => params}, socket) do
    user = socket.assigns.current_scope.user
    request = socket.assigns.request

    attrs = %{
      "donor_id" => user.id,
      "request_id" => request.id,
      "amount" => params["amount"]
    }

    case Donations.create_donation(attrs) do
      {:ok, _donation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Donacion registrada exitosamente. Estado: pendiente de confirmacion.")
         |> assign(:show_modal, false)
         |> push_navigate(to: ~p"/donor/donations")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "donation"))}
    end
  end

end
