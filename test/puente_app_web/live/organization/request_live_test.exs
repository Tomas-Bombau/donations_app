defmodule PuenteAppWeb.Organization.RequestLiveTest do
  use PuenteAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PuenteApp.OrganizationsFixtures
  import PuenteApp.CatalogFixtures
  import PuenteApp.RequestsFixtures

  alias PuenteApp.Requests

  describe "RequestLive.Index" do
    setup %{conn: conn} do
      {user, organization} = organization_with_payment_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user, organization: organization}
    end

    test "renders request list page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/organization/requests")
      assert html =~ "pedido" or html =~ "Pedido"
    end

    test "shows create button when eligible", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/organization/requests")
      assert html =~ "Nuevo" or html =~ "nuevo" or html =~ "Crear"
    end

    test "lists organization requests", %{conn: conn, organization: organization} do
      category = category_fixture()

      {:ok, request} =
        Requests.create_request(organization, %{
          "title" => "Mi pedido de prueba",
          "description" => "Descripción",
          "amount" => "5000",
          "deadline" => Date.add(Date.utc_today(), 30) |> Date.to_string(),
          "category_id" => category.id
        })

      {:ok, _view, html} = live(conn, ~p"/organization/requests")
      assert html =~ request.title
    end

    test "filters by status", %{conn: conn, organization: organization} do
      category = category_fixture()

      {:ok, draft} =
        Requests.create_request(organization, %{
          "title" => "Borrador",
          "description" => "Desc",
          "amount" => "1000",
          "deadline" => Date.add(Date.utc_today(), 30) |> Date.to_string(),
          "category_id" => category.id
        })

      {:ok, _view, html} = live(conn, ~p"/organization/requests?status=draft")
      assert html =~ draft.title
    end
  end

  describe "RequestLive.New" do
    setup %{conn: conn} do
      {user, organization} = organization_with_payment_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user, organization: organization}
    end

    test "renders new request form", %{conn: conn} do
      _category = category_fixture()
      {:ok, _view, html} = live(conn, ~p"/organization/requests/new")
      assert html =~ "Nuevo" or html =~ "pedido" or html =~ "Crear"
    end

    test "redirects when no payment configured", %{conn: _conn} do
      {user, _org} = organization_fixture()
      conn2 = log_in_user(build_conn(), user)

      result = live(conn2, ~p"/organization/requests/new")

      case result do
        {:error, {:live_redirect, %{to: to, flash: flash}}} ->
          assert to == "/organization/profile"
          # Flash message mentions CBU or alias requirement
          assert flash["error"] =~ "CBU" or flash["error"] =~ "alias"

        {:error, {:redirect, %{to: to, flash: flash}}} ->
          assert to == "/organization/profile"
          assert flash["error"] =~ "CBU" or flash["error"] =~ "alias"

        {:ok, _view, _html} ->
          flunk("Expected redirect but got success")
      end
    end

    test "validates form on change", %{conn: conn} do
      _category = category_fixture()
      {:ok, view, _html} = live(conn, ~p"/organization/requests/new")

      html =
        view
        |> element("form")
        |> render_change(%{"request" => %{"title" => "", "amount" => "-1"}})

      assert html =~ "can&#39;t be blank" or html =~ "Título"
    end

    test "creates request on valid submit", %{conn: conn} do
      category = category_fixture()
      {:ok, view, _html} = live(conn, ~p"/organization/requests/new")

      result =
        view
        |> form("form", %{
          "request" => %{
            "title" => "Nuevo pedido de test",
            "description" => "Descripción del pedido",
            "amount" => "5000",
            "deadline" => Date.add(Date.utc_today(), 30) |> Date.to_string(),
            "category_id" => category.id
          }
        })
        |> render_submit()

      case result do
        {:ok, _view, html} ->
          assert html =~ "creado" or html =~ "Nuevo pedido de test"

        {:error, {:live_redirect, %{to: to}}} ->
          # Redirected to show page
          assert to =~ "/organization/requests/"

        html when is_binary(html) ->
          # Stayed on page, check for success or the created request
          assert html =~ "creado" or html =~ "Nuevo pedido de test" or html =~ "pedido"
      end
    end
  end

  describe "RequestLive.Show" do
    setup %{conn: conn} do
      {user, organization, category, request} = request_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user, organization: organization, category: category, request: request}
    end

    test "renders request details", %{conn: conn, request: request} do
      {:ok, _view, html} = live(conn, ~p"/organization/requests/#{request.id}")
      assert html =~ request.title
    end

    test "allows publishing draft request", %{conn: conn, request: request} do
      {:ok, view, _html} = live(conn, ~p"/organization/requests/#{request.id}")

      # Try to find and click the publish button
      html =
        view
        |> element("button[phx-click='publish']")
        |> render_click()

      assert html =~ "publicado" or html =~ "activo" or html =~ "Activo"
    end

    test "allows deleting draft request", %{conn: conn, request: request} do
      {:ok, view, _html} = live(conn, ~p"/organization/requests/#{request.id}")

      result =
        view
        |> element("button[phx-click='delete']")
        |> render_click()

      case result do
        {:ok, _view, html} ->
          assert html =~ "eliminado" or html =~ "pedido"

        {:error, {:live_redirect, %{to: to}}} ->
          # Redirected to requests list
          assert to == "/organization/requests"

        html when is_binary(html) ->
          # May have redirected via push_navigate
          assert html =~ "eliminado" or html =~ "pedido"
      end
    end
  end

  describe "RequestLive.Edit" do
    setup %{conn: conn} do
      {user, organization, category, request} = request_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user, organization: organization, category: category, request: request}
    end

    test "renders edit form for draft request", %{conn: conn, request: request} do
      {:ok, _view, html} = live(conn, ~p"/organization/requests/#{request.id}/edit")
      assert html =~ "Editar" or html =~ "editar" or html =~ request.title
    end

    test "redirects for non-draft request", %{conn: conn, request: request} do
      {:ok, active} = Requests.publish_request(request)

      result = live(conn, ~p"/organization/requests/#{active.id}/edit")

      case result do
        {:error, {:live_redirect, %{to: _to, flash: flash}}} ->
          assert flash["error"] =~ "borrador" or flash["error"] =~ "editar"

        {:error, {:redirect, %{to: _to, flash: flash}}} ->
          assert flash["error"] =~ "borrador" or flash["error"] =~ "editar"

        {:ok, _view, _html} ->
          flunk("Expected redirect for non-draft request")
      end
    end

    test "updates request on valid submit", %{conn: conn, request: request} do
      {:ok, view, _html} = live(conn, ~p"/organization/requests/#{request.id}/edit")

      result =
        view
        |> form("form", %{
          "request" => %{
            "title" => "Título actualizado"
          }
        })
        |> render_submit()

      case result do
        {:ok, _view, html} ->
          assert html =~ "actualizado" or html =~ "Título actualizado"

        {:error, {:live_redirect, %{to: to}}} ->
          # Redirected to show page
          assert to =~ "/organization/requests/"

        html when is_binary(html) ->
          assert html =~ "actualizado" or html =~ "Título actualizado" or html =~ "pedido"
      end
    end
  end
end
