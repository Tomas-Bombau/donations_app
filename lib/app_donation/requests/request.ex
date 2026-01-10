defmodule AppDonation.Requests.Request do
  use AppDonation, :schema
  import Ecto.Changeset

  alias AppDonation.Organizations.Organization
  alias AppDonation.Catalog.Category

  @statuses [:draft, :active, :completed]

  schema "requests" do
    field :title, :string
    field :description, :string
    field :amount, :decimal
    field :amount_raised, :decimal, default: Decimal.new(0)
    field :reference_links, {:array, :string}, default: []
    field :deadline, :date
    field :status, Ecto.Enum, values: @statuses, default: :draft

    belongs_to :organization, Organization
    belongs_to :category, Category

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def status_options do
    [
      {"Borrador", :draft},
      {"Activo", :active},
      {"Finalizado", :completed}
    ]
  end

  @doc """
  Changeset for creating a new request.
  """
  def create_changeset(request, attrs) do
    request
    |> cast(attrs, [:title, :description, :amount, :reference_links, :deadline, :category_id, :organization_id])
    |> validate_required([:title, :description, :amount, :deadline, :category_id, :organization_id])
    |> validate_length(:title, max: 200)
    |> validate_length(:description, max: 5000)
    |> validate_number(:amount, greater_than: 0)
    |> validate_deadline_in_future()
    |> validate_reference_links()
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:category_id)
  end

  @doc """
  Changeset for updating a draft request.
  """
  def update_changeset(request, attrs) do
    request
    |> cast(attrs, [:title, :description, :amount, :reference_links, :deadline, :category_id])
    |> validate_required([:title, :description, :amount, :deadline, :category_id])
    |> validate_length(:title, max: 200)
    |> validate_length(:description, max: 5000)
    |> validate_number(:amount, greater_than: 0)
    |> validate_deadline_in_future()
    |> validate_reference_links()
    |> foreign_key_constraint(:category_id)
  end

  @doc """
  Changeset for publishing a request (draft -> active).
  """
  def publish_changeset(request) do
    if request.status == :draft do
      change(request, status: :active)
    else
      request
      |> change()
      |> add_error(:status, "solo se pueden publicar pedidos en borrador")
    end
  end

  @doc """
  Changeset for completing/finalizing a request (active -> completed).
  """
  def complete_changeset(request) do
    if request.status == :active do
      change(request, status: :completed)
    else
      request
      |> change()
      |> add_error(:status, "solo se pueden finalizar pedidos activos")
    end
  end

  @doc """
  Changeset for adding a donation amount.
  """
  def add_donation_changeset(request, amount) do
    new_amount = Decimal.add(request.amount_raised, amount)
    change(request, amount_raised: new_amount)
  end

  @doc """
  Checks if the request has reached its funding goal.
  """
  def goal_reached?(%__MODULE__{amount: amount, amount_raised: amount_raised}) do
    Decimal.compare(amount_raised, amount) != :lt
  end

  defp validate_deadline_in_future(changeset) do
    case get_change(changeset, :deadline) do
      nil ->
        changeset

      deadline ->
        if Date.compare(deadline, Date.utc_today()) == :gt do
          changeset
        else
          add_error(changeset, :deadline, "debe ser una fecha futura")
        end
    end
  end

  defp validate_reference_links(changeset) do
    case get_change(changeset, :reference_links) do
      nil ->
        changeset

      links ->
        invalid_links =
          Enum.reject(links, fn link ->
            String.starts_with?(link, "http://") or String.starts_with?(link, "https://")
          end)

        if Enum.empty?(invalid_links) do
          changeset
        else
          add_error(changeset, :reference_links, "todos los links deben comenzar con http:// o https://")
        end
    end
  end
end
