defmodule AppDonation.Organizations do
  @moduledoc """
  The Organizations context.
  """

  import Ecto.Query, warn: false
  alias AppDonation.Repo
  alias AppDonation.Organizations.Organization

  @doc """
  Creates an organization profile.
  """
  def create_organization(attrs) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an organization profile.
  """
  def update_organization(%Organization{} = organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates organization profile with payment info.
  """
  def update_organization_profile(%Organization{} = organization, attrs) do
    organization
    |> Organization.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a changeset for tracking profile changes.
  """
  def change_organization_profile(%Organization{} = organization, attrs \\ %{}) do
    Organization.profile_changeset(organization, attrs)
  end

  @doc """
  Gets an organization by user_id.
  """
  def get_organization_by_user_id(user_id) do
    Repo.get_by(Organization, user_id: user_id)
  end

  @doc """
  Returns a changeset for tracking organization changes.
  """
  def change_organization(%Organization{} = organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
  end
end
