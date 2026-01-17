defmodule PuenteApp.Donations.Donation do
  use PuenteApp, :schema
  import Ecto.Changeset

  alias PuenteApp.Accounts.User
  alias PuenteApp.Requests.Request

  schema "donations" do
    field :amount, :decimal

    belongs_to :donor, User, foreign_key: :donor_id
    belongs_to :request, Request

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new donation.
  """
  def create_changeset(donation, attrs) do
    donation
    |> cast(attrs, [:amount, :donor_id, :request_id])
    |> validate_required([:amount, :donor_id, :request_id])
    |> validate_number(:amount, greater_than: 0)
    |> foreign_key_constraint(:donor_id)
    |> foreign_key_constraint(:request_id)
  end
end
