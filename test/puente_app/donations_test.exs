defmodule PuenteApp.DonationsTest do
  use PuenteApp.DataCase

  alias PuenteApp.Donations
  alias PuenteApp.Donations.Donation

  import PuenteApp.AccountsFixtures
  import PuenteApp.RequestsFixtures
  import PuenteApp.DonationsFixtures

  describe "create_donation/1" do
    test "creates donation with valid data" do
      {_user, _org, _cat, request} = active_request_fixture()
      donor = user_fixture()

      attrs = %{
        "amount" => "1000",
        "donor_id" => donor.id,
        "request_id" => request.id
      }

      assert {:ok, %Donation{} = donation} = Donations.create_donation(attrs)
      assert Decimal.equal?(donation.amount, Decimal.new("1000"))
      assert donation.donor_id == donor.id
      assert donation.request_id == request.id
      assert donation.status == :pending
    end

    test "returns error with invalid data" do
      assert {:error, %Ecto.Changeset{}} = Donations.create_donation(%{})
    end

    test "validates amount is positive" do
      {_user, _org, _cat, request} = active_request_fixture()
      donor = user_fixture()

      attrs = %{
        "amount" => "-100",
        "donor_id" => donor.id,
        "request_id" => request.id
      }

      assert {:error, changeset} = Donations.create_donation(attrs)
      assert "must be greater than 0" in errors_on(changeset).amount
    end

    test "validates required fields" do
      assert {:error, changeset} = Donations.create_donation(%{"amount" => "100"})
      assert "can't be blank" in errors_on(changeset).donor_id
      assert "can't be blank" in errors_on(changeset).request_id
    end
  end

  describe "list_donations_for_donor/2" do
    test "returns donations for donor" do
      %{donation: donation, donor: donor} = donation_fixture()

      {donations, count} = Donations.list_donations_for_donor(donor.id)
      assert count == 1
      assert hd(donations).id == donation.id
    end

    test "returns empty list for donor with no donations" do
      donor = user_fixture()
      {donations, count} = Donations.list_donations_for_donor(donor.id)
      assert count == 0
      assert donations == []
    end

    test "paginates results" do
      %{donor: donor} = donation_fixture()
      {donations, _} = Donations.list_donations_for_donor(donor.id, page: 1, per_page: 1)
      assert length(donations) == 1
    end

    test "preloads request with associations" do
      %{donor: donor} = donation_fixture()
      {[donation], _} = Donations.list_donations_for_donor(donor.id)

      assert donation.request != nil
      assert donation.request.category != nil
      assert donation.request.organization != nil
    end
  end

  describe "change_donation/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = Donations.change_donation(%Donation{})
    end

    test "returns changeset with attrs" do
      changeset = Donations.change_donation(%Donation{}, %{"amount" => "500"})
      assert %Ecto.Changeset{} = changeset
    end
  end
end
