defmodule PuenteApp.DonationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PuenteApp.Donations` context.
  """

  alias PuenteApp.Donations
  alias PuenteApp.RequestsFixtures
  alias PuenteApp.AccountsFixtures

  def valid_donation_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      "amount" => "500"
    })
  end

  def donation_fixture(attrs \\ %{}) do
    {org_user, organization, category, request} = RequestsFixtures.active_request_fixture()
    donor = AccountsFixtures.user_fixture()

    {:ok, donation} =
      attrs
      |> valid_donation_attributes()
      |> Map.put("donor_id", donor.id)
      |> Map.put("request_id", request.id)
      |> Donations.create_donation()

    %{
      donation: donation,
      donor: donor,
      request: request,
      organization: organization,
      org_user: org_user,
      category: category
    }
  end
end
