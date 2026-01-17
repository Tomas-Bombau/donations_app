defmodule PuenteApp.OrganizationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PuenteApp.Organizations` context.
  """

  alias PuenteApp.Organizations
  alias PuenteApp.AccountsFixtures

  def valid_organization_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      organization_name: "Organización Test #{System.unique_integer()}",
      organization_role: "presidente",
      province: "CABA"
    })
  end

  def organization_fixture(attrs \\ %{}) do
    user = AccountsFixtures.organization_user_fixture()

    {:ok, organization} =
      attrs
      |> valid_organization_attributes()
      |> Map.put(:user_id, user.id)
      |> Organizations.register_organization()

    {user, organization}
  end

  def organization_with_payment_fixture(attrs \\ %{}) do
    {user, organization} = organization_fixture(attrs)

    {:ok, organization} =
      Organizations.update_organization_profile(organization, %{
        address: "Calle Falsa 123",
        cbu: "0000000000000000000001"
      })

    {user, organization}
  end
end
