defmodule PuenteApp.Donations.Donation do
  use PuenteApp, :schema
  import Ecto.Changeset

  alias PuenteApp.Accounts.User
  alias PuenteApp.Requests.Request

  @statuses [:pending, :completed, :cancelled]

  schema "donations" do
    field :amount, :decimal
    field :status, Ecto.Enum, values: @statuses, default: :pending

    belongs_to :donor, User, foreign_key: :donor_id
    belongs_to :request, Request

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def status_options do
    [
      {"Pendiente", :pending},
      {"Completada", :completed},
      {"Cancelada", :cancelled}
    ]
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

  @doc """
  Changeset for updating donation status.
  """
  def status_changeset(donation, status) do
    change(donation, status: status)
  end
end
