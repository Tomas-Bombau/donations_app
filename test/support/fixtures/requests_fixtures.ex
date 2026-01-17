defmodule PuenteApp.RequestsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PuenteApp.Requests` context.
  """

  alias PuenteApp.Requests
  alias PuenteApp.OrganizationsFixtures
  alias PuenteApp.CatalogFixtures

  def valid_request_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      "title" => "Pedido de donación #{System.unique_integer()}",
      "description" => "Descripción del pedido de donación para ayudar a la comunidad",
      "amount" => "10000",
      "deadline" => Date.add(Date.utc_today(), 30) |> Date.to_string(),
      "reference_links" => []
    })
  end

  def request_fixture(attrs \\ %{}) do
    {user, organization} = OrganizationsFixtures.organization_with_payment_fixture()
    category = CatalogFixtures.category_fixture()

    {:ok, request} =
      attrs
      |> valid_request_attributes()
      |> Map.put("category_id", category.id)
      |> then(&Requests.create_request(organization, &1))

    {user, organization, category, request}
  end

  def draft_request_fixture(attrs \\ %{}) do
    request_fixture(attrs)
  end

  def active_request_fixture(attrs \\ %{}) do
    {user, organization, category, request} = request_fixture(attrs)
    {:ok, request} = Requests.publish_request(request)
    {user, organization, category, request}
  end
end
