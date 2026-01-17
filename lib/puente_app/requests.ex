defmodule PuenteApp.Requests do
  @moduledoc """
  The Requests context for managing donation requests.
  """

  import Ecto.Query, warn: false
  alias PuenteApp.Repo
  alias PuenteApp.Requests.Request
  alias PuenteApp.Organizations.Organization

  @doc """
  Lists requests for an organization with pagination.
  """
  def list_requests_for_organization(organization_id, opts \\ []) do
    status = Keyword.get(opts, :status)
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 5)
    offset = (page - 1) * per_page

    query =
      Request
      |> where(organization_id: ^organization_id)
      |> preload(:category)
      |> order_by(desc: :inserted_at)

    query =
      if status && status != "" && status != "all" do
        status_atom = if is_binary(status), do: String.to_existing_atom(status), else: status
        where(query, status: ^status_atom)
      else
        query
      end

    total_count = Repo.aggregate(query, :count, :id)

    requests =
      query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    {requests, total_count}
  end

  @doc """
  Lists active requests (for public/donors view).
  """
  def list_active_requests(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 5)
    category_id = Keyword.get(opts, :category_id)
    province = Keyword.get(opts, :province)
    municipality = Keyword.get(opts, :municipality)
    offset = (page - 1) * per_page

    query =
      Request
      |> where(status: :active)
      |> join(:inner, [r], o in assoc(r, :organization), as: :org)
      |> preload([:category, organization: :user])
      |> order_by(asc: :deadline)

    query =
      if category_id && category_id != "" do
        where(query, category_id: ^category_id)
      else
        query
      end

    query =
      if province && province != "" do
        where(query, [r, org: o], o.province == ^province)
      else
        query
      end

    query =
      if municipality && municipality != "" do
        where(query, [r, org: o], o.municipality == ^municipality)
      else
        query
      end

    total_count = Repo.aggregate(query, :count, :id)

    requests =
      query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    {requests, total_count}
  end

  @doc """
  Gets a single request.

  Raises `Ecto.NoResultsError` if the Request does not exist.
  """
  def get_request!(id) do
    Request
    |> preload([:category, organization: :user])
    |> Repo.get!(id)
  end

  @doc """
  Gets a request for a specific organization.

  Raises `Ecto.NoResultsError` if the Request does not exist or doesn't belong to the organization.
  """
  def get_request_for_organization!(id, organization_id) do
    Request
    |> where(id: ^id, organization_id: ^organization_id)
    |> preload(:category)
    |> Repo.one!()
  end

  @doc """
  Creates a request for an organization.
  Returns error if:
  - Organization doesn't have payment configured
  - Organization has an active request
  - Organization has a completed request pending closure (accountability report)
  """
  def create_request(%Organization{} = organization, attrs) do
    cond do
      not Organization.has_payment_configured?(organization) ->
        {:error, :payment_not_configured}

      has_active_request?(organization.id) ->
        {:error, :has_active_request}

      has_pending_closure?(organization.id) ->
        {:error, :pending_closure}

      true ->
        attrs = Map.put(attrs, "organization_id", organization.id)

        %Request{}
        |> Request.create_changeset(attrs)
        |> Repo.insert()
    end
  end

  @doc """
  Checks if the organization has an active request.
  """
  def has_active_request?(organization_id) do
    Request
    |> where(organization_id: ^organization_id, status: :active)
    |> Repo.exists?()
  end

  @doc """
  Checks if the organization has a completed request pending closure.
  Returns true if there's at least one request in 'completed' status without accountability report.
  """
  def has_pending_closure?(organization_id) do
    Request
    |> where(organization_id: ^organization_id, status: :completed)
    |> Repo.exists?()
  end

  @doc """
  Gets the request pending closure for an organization (if any).
  """
  def get_pending_closure(organization_id) do
    Request
    |> where(organization_id: ^organization_id, status: :completed)
    |> preload(:category)
    |> order_by(desc: :updated_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Updates a draft request.
  """
  def update_request(%Request{status: :draft} = request, attrs) do
    request
    |> Request.update_changeset(attrs)
    |> Repo.update()
  end

  def update_request(%Request{}, _attrs) do
    {:error, :cannot_update_published}
  end

  @doc """
  Publishes a draft request (draft -> active).
  """
  def publish_request(%Request{} = request) do
    request
    |> Request.publish_changeset()
    |> Repo.update()
  end

  @doc """
  Completes/finalizes an active request.
  """
  def complete_request(%Request{} = request) do
    request
    |> Request.complete_changeset()
    |> Repo.update()
  end

  @doc """
  Deletes a draft request.
  """
  def delete_request(%Request{status: :draft} = request) do
    Repo.delete(request)
  end

  def delete_request(%Request{}) do
    {:error, :cannot_delete_published}
  end

  @doc """
  Completes all active requests past their deadline.
  Returns the count of completed requests.
  """
  def complete_past_deadline_requests do
    today = Date.utc_today()

    {count, _} =
      Request
      |> where(status: :active)
      |> where([r], r.deadline < ^today)
      |> Repo.update_all(set: [status: :completed, updated_at: DateTime.utc_now(:second)])

    count
  end

  @doc """
  Adds a donation to a request and checks if goal is reached.
  If goal is reached, automatically completes the request.
  """
  def add_donation(%Request{status: :active} = request, amount) do
    request
    |> Request.add_donation_changeset(amount)
    |> Repo.update()
    |> case do
      {:ok, updated_request} ->
        if Request.goal_reached?(updated_request) do
          complete_request(updated_request)
        else
          {:ok, updated_request}
        end

      error ->
        error
    end
  end

  def add_donation(%Request{}, _amount) do
    {:error, :request_not_active}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking request changes.
  """
  def change_request(%Request{} = request, attrs \\ %{}) do
    Request.create_changeset(request, attrs)
  end

  @doc """
  Closes a completed request with an accountability report (completed -> closed).
  """
  def close_request(%Request{status: :completed} = request, attrs) do
    request
    |> Request.close_changeset(attrs)
    |> Repo.update()
  end

  def close_request(%Request{}, _attrs) do
    {:error, :cannot_close_not_completed}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking closure form changes.
  """
  def change_closure(%Request{} = request, attrs \\ %{}) do
    Request.closure_changeset(request, attrs)
  end
end
