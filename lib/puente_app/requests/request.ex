defmodule PuenteApp.Requests.Request do
  use PuenteApp, :schema
  import Ecto.Changeset

  alias PuenteApp.Organizations.Organization
  alias PuenteApp.Catalog.Category

  @statuses [:draft, :active, :completed, :closed]

  schema "requests" do
    field :title, :string
    field :description, :string
    field :amount, :decimal
    field :amount_raised, :decimal, default: Decimal.new(0)
    field :reference_links, {:array, :string}, default: []
    field :deadline, :date
    field :status, Ecto.Enum, values: @statuses, default: :draft

    # Closure/accountability fields
    field :closing_message, :string
    field :outcome_description, :string
    field :outcome_images, {:array, :string}, default: []
    field :closed_at, :utc_datetime

    belongs_to :organization, Organization
    belongs_to :category, Category

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def status_options do
    [
      {"Borrador", :draft},
      {"Activo", :active},
      {"Finalizado", :completed},
      {"Cerrado", :closed}
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
  Changeset for closing a request with accountability report (completed -> closed).
  """
  def close_changeset(request, attrs) do
    if request.status == :completed do
      request
      |> cast(attrs, [:closing_message, :outcome_description, :outcome_images])
      |> validate_required([:closing_message, :outcome_description])
      |> validate_length(:closing_message, max: 2000)
      |> validate_length(:outcome_description, max: 5000)
      |> put_change(:status, :closed)
      |> put_change(:closed_at, DateTime.utc_now(:second))
    else
      request
      |> change()
      |> add_error(:status, "solo se pueden cerrar pedidos finalizados")
    end
  end

  @doc """
  Changeset for tracking closure form changes (for LiveView forms).
  """
  def closure_changeset(request, attrs \\ %{}) do
    request
    |> cast(attrs, [:closing_message, :outcome_description, :outcome_images])
    |> validate_required([:closing_message, :outcome_description])
    |> validate_length(:closing_message, max: 2000)
    |> validate_length(:outcome_description, max: 5000)
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
