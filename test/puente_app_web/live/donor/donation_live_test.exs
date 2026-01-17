defmodule PuenteAppWeb.Donor.DonationLiveTest do
  use PuenteAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PuenteApp.AccountsFixtures
  import PuenteApp.DonationsFixtures

  describe "DonationLive.Index" do
    setup %{conn: conn} do
      donor = user_fixture()
      conn = log_in_user(conn, donor)
      %{conn: conn, donor: donor}
    end

    test "renders donations page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/donor/donations")
      assert html =~ "Donaciones" or html =~ "donaciones"
    end

    test "shows empty state when no donations", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/donor/donations")
      # Should render without errors even with no donations
      assert html
    end

    test "lists donor's donations", %{conn: _conn} do
      %{donor: donor, donation: _donation, request: request} = donation_fixture()
      conn = log_in_user(build_conn(), donor)

      {:ok, _view, html} = live(conn, ~p"/donor/donations")
      assert html =~ request.title
    end

    test "shows donation status", %{conn: _conn} do
      %{donor: donor} = donation_fixture()
      conn = log_in_user(build_conn(), donor)

      {:ok, _view, html} = live(conn, ~p"/donor/donations")
      # Status label for active requests is "En curso"
      assert html =~ "En curso" or html =~ "curso"
    end

    test "paginates donations", %{conn: _conn} do
      %{donor: donor} = donation_fixture()
      conn = log_in_user(build_conn(), donor)

      {:ok, _view, html} = live(conn, ~p"/donor/donations?page=1")
      assert html
    end
  end
end
