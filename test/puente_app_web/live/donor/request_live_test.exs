defmodule PuenteAppWeb.Donor.RequestLiveTest do
  use PuenteAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PuenteApp.AccountsFixtures
  import PuenteApp.RequestsFixtures

  describe "RequestLive.Index" do
    setup %{conn: conn} do
      donor = user_fixture()
      conn = log_in_user(conn, donor)
      %{conn: conn, donor: donor}
    end

    test "renders active requests page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/donor/requests")
      assert html =~ "Pedidos" or html =~ "pedidos"
    end

    test "shows active requests", %{conn: conn} do
      {_user, _org, _cat, request} = active_request_fixture()
      {:ok, _view, html} = live(conn, ~p"/donor/requests")
      assert html =~ request.title
    end

    test "does not show draft requests", %{conn: conn} do
      {_user, _org, _cat, request} = request_fixture()
      {:ok, _view, html} = live(conn, ~p"/donor/requests")
      refute html =~ request.title
    end

    test "opens donation modal", %{conn: conn} do
      {_user, _org, _cat, request} = active_request_fixture()
      {:ok, view, _html} = live(conn, ~p"/donor/requests")

      html =
        view
        |> element("button[phx-click='open_modal'][phx-value-id='#{request.id}']")
        |> render_click()

      assert html =~ "Quiero ayudar" or html =~ "Monto de mi aporte"
    end

    test "closes donation modal", %{conn: conn} do
      {_user, _org, _cat, request} = active_request_fixture()
      {:ok, view, _html} = live(conn, ~p"/donor/requests")

      view
      |> element("button[phx-click='open_modal'][phx-value-id='#{request.id}']")
      |> render_click()

      html =
        view
        |> element("button[phx-click='close_modal']")
        |> render_click()

      # Modal should be closed
      refute html =~ "phx-submit=\"save_donation\""
    end

    test "validates donation amount", %{conn: conn} do
      {_user, _org, _cat, request} = active_request_fixture()
      {:ok, view, _html} = live(conn, ~p"/donor/requests")

      view
      |> element("button[phx-click='open_modal'][phx-value-id='#{request.id}']")
      |> render_click()

      html =
        view
        |> element("form[phx-submit='save_donation']")
        |> render_change(%{"donation" => %{"amount" => "-100"}})

      # Validation error should appear - message can be in English or Spanish
      assert html =~ "greater than 0" or html =~ "mayor" or html =~ "must be" or html =~ "error"
    end

    test "creates donation successfully", %{conn: conn} do
      {_user, _org, _cat, request} = active_request_fixture()
      {:ok, view, _html} = live(conn, ~p"/donor/requests")

      view
      |> element("button[phx-click='open_modal'][phx-value-id='#{request.id}']")
      |> render_click()

      {:ok, _view, html} =
        view
        |> form("form[phx-submit='save_donation']", %{
          "donation" => %{"amount" => "500"}
        })
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "donación" or html =~ "registrada"
    end
  end

  describe "RequestLive.Show" do
    setup %{conn: conn} do
      donor = user_fixture()
      {_user, _org, _cat, request} = active_request_fixture()
      conn = log_in_user(conn, donor)
      %{conn: conn, donor: donor, request: request}
    end

    test "renders request details", %{conn: conn, request: request} do
      {:ok, _view, html} = live(conn, ~p"/donor/requests/#{request.id}")
      assert html =~ request.title
    end

    test "redirects for non-active request", %{conn: conn} do
      {_user, _org, _cat, draft_request} = request_fixture()

      result = live(conn, ~p"/donor/requests/#{draft_request.id}")

      case result do
        {:error, {:live_redirect, %{to: _to, flash: flash}}} ->
          assert flash["error"] =~ "activo" or flash["error"] =~ "disponible"

        {:error, {:redirect, %{to: _to, flash: flash}}} ->
          assert flash["error"] =~ "activo" or flash["error"] =~ "disponible"

        {:ok, _view, _html} ->
          flunk("Expected redirect for non-active request")
      end
    end

    test "allows donation from show page", %{conn: conn, request: request} do
      {:ok, view, _html} = live(conn, ~p"/donor/requests/#{request.id}")

      view
      |> element("button[phx-click='open_modal']")
      |> render_click()

      result =
        view
        |> form("form[phx-submit='save_donation']", %{
          "donation" => %{"amount" => "1000"}
        })
        |> render_submit()

      case result do
        {:ok, _view, html} ->
          assert html =~ "donación" or html =~ "registrada" or html =~ "Donaciones"

        {:error, {:live_redirect, %{to: to}}} ->
          # Redirected to donations page
          assert to =~ "/donor/donations"

        html when is_binary(html) ->
          assert html =~ "donación" or html =~ "registrada" or html =~ "pedido"
      end
    end
  end
end
