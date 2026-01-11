defmodule PuenteApp.Donations do
  @moduledoc """
  The Donations context for managing donation records.
  """

  import Ecto.Query, warn: false
  alias PuenteApp.Repo
  alias PuenteApp.Donations.Donation
  alias PuenteApp.Requests

  @doc """
  Creates a donation with pending status.
  """
  def create_donation(attrs) do
    %Donation{}
    |> Donation.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single donation.

  Raises `Ecto.NoResultsError` if the Donation does not exist.
  """
  def get_donation!(id) do
    Donation
    |> preload(request: [:category, organization: :user])
    |> Repo.get!(id)
  end

  @doc """
  Gets a donation for a specific donor.

  Raises `Ecto.NoResultsError` if the Donation does not exist or doesn't belong to the donor.
  """
  def get_donation_for_donor!(id, donor_id) do
    Donation
    |> where(id: ^id, donor_id: ^donor_id)
    |> preload(request: [:category, organization: :user])
    |> Repo.one!()
  end

  @doc """
  Lists donations for a donor with pagination.
  """
  def list_donations_for_donor(donor_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 5)
    offset = (page - 1) * per_page

    query =
      Donation
      |> where(donor_id: ^donor_id)
      |> preload(request: [:category, organization: :user])
      |> order_by(desc: :inserted_at)

    total_count = Repo.aggregate(query, :count, :id)

    donations =
      query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    {donations, total_count}
  end

  @doc """
  Lists donations for a request.
  """
  def list_donations_for_request(request_id) do
    Donation
    |> where(request_id: ^request_id)
    |> preload(:donor)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Completes a donation (pending -> completed).
  Updates the request's amount_raised.
  """
  def complete_donation(%Donation{status: :pending} = donation) do
    donation = Repo.preload(donation, :request)

    Repo.transaction(fn ->
      with {:ok, updated_donation} <- update_status(donation, :completed),
           {:ok, _request} <- Requests.add_donation(donation.request, donation.amount) do
        updated_donation
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def complete_donation(%Donation{}) do
    {:error, :invalid_status}
  end

  @doc """
  Cancels a donation (pending -> cancelled).
  """
  def cancel_donation(%Donation{status: :pending} = donation) do
    update_status(donation, :cancelled)
  end

  def cancel_donation(%Donation{}) do
    {:error, :invalid_status}
  end

  defp update_status(donation, status) do
    donation
    |> Donation.status_changeset(status)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking donation changes.
  """
  def change_donation(%Donation{} = donation, attrs \\ %{}) do
    Donation.create_changeset(donation, attrs)
  end
end
