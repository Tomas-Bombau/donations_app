defmodule PuenteApp.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias PuenteApp.Repo

  alias PuenteApp.Accounts.{User, UserToken, UserNotifier}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password) and user.archived != true, do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by ID, ensuring they have the :organization role.
  Raises `Ecto.NoResultsError` if not found or wrong role.
  """
  def get_organization_user!(id) do
    User
    |> where(id: ^id, role: :organization)
    |> Repo.one!()
  end

  @doc """
  Gets a user by ID, ensuring they have the :donor role.
  Raises `Ecto.NoResultsError` if not found or wrong role.
  """
  def get_donor_user!(id) do
    User
    |> where(id: ^id, role: :donor)
    |> Repo.one!()
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Registers an organization user (phone required).
  """
  def register_organization_user(attrs) do
    %User{}
    |> User.organization_registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user registration changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_unique: false)
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `PuenteApp.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `PuenteApp.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given email confirmation token.
  Returns the user if the token is valid, nil otherwise.
  """
  def get_user_by_confirmation_token(token) do
    with {:ok, query} <- UserToken.verify_email_confirmation_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Confirms the user's email by token.

  If the token is valid and the user is not already confirmed,
  the user's `confirmed_at` field is set and the token is deleted.
  """
  def confirm_user_by_token(token) do
    with {:ok, query} <- UserToken.verify_email_confirmation_token_query(token),
         {user, token_record} <- Repo.one(query) do
      Repo.transact(fn ->
        case user do
          %User{confirmed_at: nil} ->
            {:ok, user} =
              user
              |> User.confirm_changeset()
              |> Repo.update()

            Repo.delete!(token_record)
            {:ok, user}

          %User{} ->
            # Already confirmed, just delete the token
            Repo.delete!(token_record)
            {:ok, user}
        end
      end)
    else
      _ -> {:error, :invalid_token}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the email confirmation instructions to the given user.
  """
  def deliver_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
    Repo.insert!(user_token)
    UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Admin functions

  @doc """
  Lists users by role with pagination (excluding archived).
  Returns {list, total_count}.
  """
  def list_users_by_role_paginated(role, page, per_page, filters \\ %{}) do
    offset = (page - 1) * per_page

    query =
      User
      |> where(role: ^role)
      |> where([u], u.archived == false or is_nil(u.archived))
      |> apply_user_search_filter(filters["search"])

    total_count = Repo.aggregate(query, :count, :id)

    users =
      query
      |> preload(:organization)
      |> order_by(desc: :inserted_at)
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    {users, total_count}
  end

  @doc """
  Lists archived users by role with pagination.
  Returns {list, total_count}.
  """
  def list_archived_users_by_role_paginated(role, page, per_page, filters \\ %{}) do
    offset = (page - 1) * per_page

    query =
      User
      |> where(role: ^role)
      |> where([u], u.archived == true)
      |> apply_user_search_filter(filters["search"])

    total_count = Repo.aggregate(query, :count, :id)

    users =
      query
      |> preload(:organization)
      |> order_by(desc: :archived_at)
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    {users, total_count}
  end

  @doc """
  Lists approved organizations with pagination and filters (excluding archived).
  Returns {list, total_count}.
  """
  def list_approved_organizations_paginated(page, per_page, filters \\ %{}) do
    offset = (page - 1) * per_page

    base_query =
      User
      |> where(role: :organization)
      |> where([u], not is_nil(u.admin_approved_at))
      |> where([u], u.archived == false or is_nil(u.archived))

    query = apply_organization_filters(base_query, filters)

    total_count = Repo.aggregate(query, :count, :id)

    organizations =
      query
      |> preload(:organization)
      |> order_by(desc: :inserted_at)
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    {organizations, total_count}
  end

  defp apply_organization_filters(query, filters) do
    province = filters["province"]
    municipality = filters["municipality"]
    has_legal_entity = filters["has_legal_entity"]
    search = filters["search"]

    needs_join = (province && province != "") || (municipality && municipality != "") ||
                 (has_legal_entity && has_legal_entity != "") || (search && search != "")

    if needs_join do
      query
      |> join(:inner, [u], o in assoc(u, :organization), as: :org)
      |> apply_province_filter(province)
      |> apply_municipality_filter(municipality)
      |> apply_legal_entity_filter(has_legal_entity)
      |> apply_org_name_search(search)
    else
      query
    end
  end

  defp apply_org_name_search(query, nil), do: query
  defp apply_org_name_search(query, ""), do: query
  defp apply_org_name_search(query, search) do
    search_term = "%#{search |> String.trim() |> String.downcase()}%"
    where(query, [u, org: o], ilike(o.organization_name, ^search_term))
  end

  defp apply_province_filter(query, nil), do: query
  defp apply_province_filter(query, ""), do: query
  defp apply_province_filter(query, province) do
    where(query, [u, org: o], o.province == ^province)
  end

  defp apply_municipality_filter(query, nil), do: query
  defp apply_municipality_filter(query, ""), do: query
  defp apply_municipality_filter(query, municipality) do
    where(query, [u, org: o], o.municipality == ^municipality)
  end

  defp apply_legal_entity_filter(query, nil), do: query
  defp apply_legal_entity_filter(query, ""), do: query
  defp apply_legal_entity_filter(query, "true") do
    where(query, [u, org: o], o.has_legal_entity == true)
  end
  defp apply_legal_entity_filter(query, "false") do
    where(query, [u, org: o], o.has_legal_entity == false or is_nil(o.has_legal_entity))
  end

  defp apply_user_search_filter(query, nil), do: query
  defp apply_user_search_filter(query, ""), do: query
  defp apply_user_search_filter(query, search) do
    search_term = "%#{search |> String.trim() |> String.downcase()}%"
    where(query, [u],
      ilike(u.first_name, ^search_term) or ilike(u.last_name, ^search_term)
    )
  end

  @doc """
  Gets a single user with preloaded profile.
  """
  def get_user_with_profile!(id) do
    User
    |> preload(:organization)
    |> Repo.get!(id)
  end

  @doc """
  Creates an organization user - admin only.
  """
  def create_organization(user_attrs, profile_attrs) do
    user_attrs = Map.put(user_attrs, "role", "organization")

    Repo.transact(fn ->
      with {:ok, user} <- register_user(user_attrs),
           {:ok, _profile} <- create_organization_profile(user, profile_attrs) do
        {:ok, Repo.preload(user, :organization)}
      end
    end)
  end

  defp create_organization_profile(user, attrs) do
    %PuenteApp.Organizations.Organization{}
    |> PuenteApp.Organizations.Organization.changeset(Map.put(attrs, "user_id", user.id))
    |> Repo.insert()
  end

  @doc """
  Updates an organization user and their profile.
  """
  def update_organization(user, user_attrs, profile_attrs) do
    Repo.transact(fn ->
      with {:ok, user} <- update_user_basic(user, user_attrs),
           {:ok, _profile} <- update_organization_profile(user, profile_attrs) do
        {:ok, Repo.preload(user, :organization, force: true)}
      end
    end)
  end

  defp update_user_basic(user, attrs) do
    user
    |> Ecto.Changeset.cast(attrs, [:first_name, :last_name, :email, :phone])
    |> Ecto.Changeset.validate_required([:first_name, :last_name, :email])
    |> Repo.update()
  end

  defp update_organization_profile(user, attrs) do
    profile = user.organization || %PuenteApp.Organizations.Organization{user_id: user.id}

    profile
    |> PuenteApp.Organizations.Organization.admin_changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  Returns a changeset for changing donor profile fields (first_name, last_name, phone, email, image_path).
  """
  def change_donor_profile(%User{} = user, attrs \\ %{}) do
    user
    |> Ecto.Changeset.cast(attrs, [:first_name, :last_name, :phone, :email, :image_path])
    |> Ecto.Changeset.validate_required([:first_name, :last_name, :email])
    |> Ecto.Changeset.validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "formato de email invalido")
    |> Ecto.Changeset.unique_constraint(:email)
  end

  @doc """
  Updates a donor's profile (first_name, last_name, phone, email, image_path).
  """
  def update_donor_profile(%User{} = user, attrs) do
    user
    |> change_donor_profile(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a changeset for updating user profile image.
  """
  def change_user_image(%User{} = user, attrs \\ %{}) do
    User.image_changeset(user, attrs)
  end

  @doc """
  Updates the user's profile image path.
  """
  def update_user_image(%User{} = user, attrs) do
    user
    |> User.image_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Archives a user (soft delete).
  """
  def archive_user(%User{} = user, archived_by_id) do
    user
    |> User.archive_changeset(archived_by_id)
    |> Repo.update()
  end

  @doc """
  Unarchives a user.
  """
  def unarchive_user(%User{} = user) do
    user
    |> User.unarchive_changeset()
    |> Repo.update()
  end

  @doc """
  Approves an organization user by admin.
  Returns {:error, :invalid_role} if user is not an organization.
  Sends an email notification to the organization.
  """
  def approve_user(%User{role: :organization} = user) do
    case user |> User.admin_approve_changeset() |> Repo.update() do
      {:ok, approved_user} ->
        # Send approval notification email
        UserNotifier.deliver_organization_approved(approved_user)
        {:ok, approved_user}

      error ->
        error
    end
  end

  def approve_user(%User{}), do: {:error, :invalid_role}

  @doc """
  Archives an organization user with role validation.
  Returns {:error, :invalid_role} if user is not an organization.
  """
  def archive_organization(%User{role: :organization} = user, archived_by_id) do
    archive_user(user, archived_by_id)
  end

  def archive_organization(%User{}, _archived_by_id), do: {:error, :invalid_role}

  @doc """
  Archives a donor user with role validation.
  Returns {:error, :invalid_role} if user is not a donor.
  """
  def archive_donor(%User{role: :donor} = user, archived_by_id) do
    archive_user(user, archived_by_id)
  end

  def archive_donor(%User{}, _archived_by_id), do: {:error, :invalid_role}

  @doc """
  Unarchives an organization user with role validation.
  Returns {:error, :invalid_role} if user is not an organization.
  """
  def unarchive_organization(%User{role: :organization} = user) do
    unarchive_user(user)
  end

  def unarchive_organization(%User{}), do: {:error, :invalid_role}

  @doc """
  Unarchives a donor user with role validation.
  Returns {:error, :invalid_role} if user is not a donor.
  """
  def unarchive_donor(%User{role: :donor} = user) do
    unarchive_user(user)
  end

  def unarchive_donor(%User{}), do: {:error, :invalid_role}

  @doc """
  Lists archived organizations with pagination and filters.
  Returns {list, total_count}.
  """
  def list_archived_organizations_paginated(page, per_page, filters \\ %{}) do
    offset = (page - 1) * per_page

    base_query =
      User
      |> where(role: :organization)
      |> where([u], u.archived == true)

    query = apply_organization_filters(base_query, filters)

    total_count = Repo.aggregate(query, :count, :id)

    organizations =
      query
      |> preload(:organization)
      |> order_by(desc: :archived_at)
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    {organizations, total_count}
  end

  @doc """
  Lists pending organization approvals with pagination and filters (excluding archived).
  Returns {list, total_count}.
  """
  def list_pending_organizations_paginated(page, per_page, filters \\ %{}) do
    offset = (page - 1) * per_page

    query =
      User
      |> where(role: :organization)
      |> where([u], is_nil(u.admin_approved_at))
      |> where([u], u.archived == false or is_nil(u.archived))
      |> apply_organization_filters(filters)

    total_count = Repo.aggregate(query, :count, :id)

    organizations =
      query
      |> preload(:organization)
      |> order_by(desc: :inserted_at)
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    {organizations, total_count}
  end

  @doc """
  Returns a changeset for creating/updating an organization.
  """
  def change_organization(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_unique: false)
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        {_count, tokens} =
          from(t in UserToken, where: t.user_id == ^user.id, select: t)
          |> Repo.delete_all()

        {:ok, {user, tokens || []}}
      end
    end)
  end
end
