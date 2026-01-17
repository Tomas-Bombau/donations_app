defmodule PuenteApp.Donations do
  @moduledoc """
  The Donations context for managing donation records.
  """

  import Ecto.Query, warn: false
  alias PuenteApp.Repo
  alias PuenteApp.Donations.Donation
  alias PuenteApp.Requests

  @doc """
  Creates a donation and updates the request's amount_raised.
  Returns {:error, :request_not_active} if the request is not active.
  """
  def create_donation(attrs) do
    Repo.transact(fn ->
      case Repo.insert(Donation.create_changeset(%Donation{}, attrs)) do
        {:ok, donation} ->
          request = Requests.get_request!(donation.request_id)

          case Requests.add_donation(request, donation.amount) do
            {:ok, _updated_request} ->
              {:ok, donation}

            {:error, :request_not_active} ->
              Repo.rollback(:request_not_active)

            {:error, reason} ->
              Repo.rollback(reason)
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Gets a single donation. Raises if not found.
  """
  def get_donation!(id) do
    Donation
    |> preload([:donor, request: [:category, organization: :user]])
    |> Repo.get!(id)
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
  Returns an `%Ecto.Changeset{}` for tracking donation changes.
  """
  def change_donation(%Donation{} = donation, attrs \\ %{}) do
    Donation.create_changeset(donation, attrs)
  end
end
