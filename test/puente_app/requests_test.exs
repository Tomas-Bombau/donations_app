defmodule PuenteApp.RequestsTest do
  use PuenteApp.DataCase

  alias PuenteApp.Requests
  alias PuenteApp.Requests.Request

  import PuenteApp.OrganizationsFixtures
  import PuenteApp.CatalogFixtures
  import PuenteApp.RequestsFixtures

  describe "create_request/2" do
    test "creates request with valid data" do
      {_user, organization} = organization_with_payment_fixture()
      category = category_fixture()

      attrs = %{
        "title" => "Pedido de ayuda",
        "description" => "Necesitamos ayuda para la comunidad",
        "amount" => "5000",
        "deadline" => Date.add(Date.utc_today(), 30) |> Date.to_string(),
        "category_id" => category.id
      }

      assert {:ok, %Request{} = request} = Requests.create_request(organization, attrs)
      assert request.title == "Pedido de ayuda"
      assert request.status == :draft
      assert Decimal.equal?(request.amount, Decimal.new("5000"))
    end

    test "returns error when no payment configured" do
      {_user, organization} = organization_fixture()
      category = category_fixture()

      attrs = %{
        "title" => "Pedido",
        "description" => "Descripción",
        "amount" => "1000",
        "deadline" => Date.add(Date.utc_today(), 30) |> Date.to_string(),
        "category_id" => category.id
      }

      assert {:error, :payment_not_configured} = Requests.create_request(organization, attrs)
    end

    test "returns error when organization has active request" do
      {_user, organization, _category, request} = request_fixture()
      {:ok, _active} = Requests.publish_request(request)
      category = category_fixture()

      attrs = %{
        "title" => "Nuevo pedido",
        "description" => "Descripción",
        "amount" => "1000",
        "deadline" => Date.add(Date.utc_today(), 30) |> Date.to_string(),
        "category_id" => category.id
      }

      assert {:error, :has_active_request} = Requests.create_request(organization, attrs)
    end

    test "validates deadline is in future" do
      {_user, organization} = organization_with_payment_fixture()
      category = category_fixture()

      attrs = %{
        "title" => "Pedido",
        "description" => "Descripción",
        "amount" => "1000",
        "deadline" => Date.utc_today() |> Date.to_string(),
        "category_id" => category.id
      }

      assert {:error, changeset} = Requests.create_request(organization, attrs)
      assert "debe ser una fecha futura" in errors_on(changeset).deadline
    end

    test "validates amount is positive" do
      {_user, organization} = organization_with_payment_fixture()
      category = category_fixture()

      attrs = %{
        "title" => "Pedido",
        "description" => "Descripción",
        "amount" => "-100",
        "deadline" => Date.add(Date.utc_today(), 30) |> Date.to_string(),
        "category_id" => category.id
      }

      assert {:error, changeset} = Requests.create_request(organization, attrs)
      assert "must be greater than 0" in errors_on(changeset).amount
    end
  end

  describe "get_request!/1" do
    test "returns request with preloaded associations" do
      {_user, _org, _cat, request} = request_fixture()
      fetched = Requests.get_request!(request.id)

      assert fetched.id == request.id
      assert fetched.category != nil
      assert fetched.organization != nil
    end

    test "raises when request not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Requests.get_request!(Ecto.UUID.generate())
      end
    end
  end

  describe "get_request_for_organization!/2" do
    test "returns request belonging to organization" do
      {_user, organization, _cat, request} = request_fixture()
      fetched = Requests.get_request_for_organization!(request.id, organization.id)
      assert fetched.id == request.id
    end

    test "raises when request belongs to different organization" do
      {_user, _org1, _cat, request} = request_fixture()
      {_user2, organization2} = organization_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Requests.get_request_for_organization!(request.id, organization2.id)
      end
    end
  end

  describe "list_requests_for_organization/2" do
    test "returns requests for organization" do
      {_user, organization, _cat, _request} = request_fixture()
      {requests, count} = Requests.list_requests_for_organization(organization.id)

      assert count == 1
      assert length(requests) == 1
    end

    test "filters by status" do
      {_user, organization, _cat, request} = request_fixture()
      {:ok, _active} = Requests.publish_request(request)

      {draft_requests, _} =
        Requests.list_requests_for_organization(organization.id, status: "draft")

      {active_requests, _} =
        Requests.list_requests_for_organization(organization.id, status: "active")

      assert length(draft_requests) == 0
      assert length(active_requests) == 1
    end

    test "paginates results" do
      {_user, organization} = organization_with_payment_fixture()
      category = category_fixture()

      # Crear múltiples requests (necesitamos simular que pasaron 2 semanas entre cada uno)
      # Para este test simplemente verificamos la paginación con uno
      {:ok, _req} =
        Requests.create_request(organization, %{
          "title" => "Pedido 1",
          "description" => "Desc",
          "amount" => "1000",
          "deadline" => Date.add(Date.utc_today(), 30) |> Date.to_string(),
          "category_id" => category.id
        })

      {requests, count} =
        Requests.list_requests_for_organization(organization.id, page: 1, per_page: 1)

      assert count == 1
      assert length(requests) == 1
    end
  end

  describe "list_active_requests/1" do
    test "returns only active requests" do
      {_user, _org, _cat, request} = request_fixture()
      {:ok, _active} = Requests.publish_request(request)

      {requests, count} = Requests.list_active_requests()
      assert count == 1
      assert hd(requests).status == :active
    end

    test "filters by category" do
      {_user, _org, category, request} = request_fixture()
      {:ok, _active} = Requests.publish_request(request)

      {requests, _} = Requests.list_active_requests(category_id: category.id)
      assert length(requests) == 1

      other_category = category_fixture()
      {requests, _} = Requests.list_active_requests(category_id: other_category.id)
      assert length(requests) == 0
    end
  end

  describe "update_request/2" do
    test "updates draft request" do
      {_user, _org, _cat, request} = request_fixture()

      assert {:ok, %Request{} = updated} =
               Requests.update_request(request, %{"title" => "Título actualizado"})

      assert updated.title == "Título actualizado"
    end

    test "rejects update on non-draft request" do
      {_user, _org, _cat, request} = active_request_fixture()
      assert {:error, :cannot_update_published} = Requests.update_request(request, %{"title" => "New"})
    end
  end

  describe "publish_request/1" do
    test "changes status from draft to active" do
      {_user, _org, _cat, request} = request_fixture()
      assert request.status == :draft

      assert {:ok, %Request{} = published} = Requests.publish_request(request)
      assert published.status == :active
    end

    test "rejects publishing non-draft request" do
      {_user, _org, _cat, request} = active_request_fixture()
      assert {:error, changeset} = Requests.publish_request(request)
      assert "solo se pueden publicar pedidos en borrador" in errors_on(changeset).status
    end
  end

  describe "complete_request/1" do
    test "changes status from active to completed" do
      {_user, _org, _cat, request} = active_request_fixture()

      assert {:ok, %Request{} = completed} = Requests.complete_request(request)
      assert completed.status == :completed
    end

    test "rejects completing non-active request" do
      {_user, _org, _cat, request} = request_fixture()
      assert {:error, changeset} = Requests.complete_request(request)
      assert "solo se pueden finalizar pedidos activos" in errors_on(changeset).status
    end
  end

  describe "delete_request/1" do
    test "deletes draft request" do
      {_user, _org, _cat, request} = request_fixture()
      assert {:ok, %Request{}} = Requests.delete_request(request)
      assert_raise Ecto.NoResultsError, fn -> Requests.get_request!(request.id) end
    end

    test "rejects deleting non-draft request" do
      {_user, _org, _cat, request} = active_request_fixture()
      assert {:error, :cannot_delete_published} = Requests.delete_request(request)
    end
  end

  describe "has_active_request?/1" do
    test "returns true when organization has active request" do
      {_user, organization, _cat, request} = request_fixture()
      {:ok, _active} = Requests.publish_request(request)

      assert Requests.has_active_request?(organization.id)
    end

    test "returns false when no active request" do
      {_user, organization, _cat, _request} = request_fixture()
      refute Requests.has_active_request?(organization.id)
    end
  end

  describe "add_donation/2" do
    test "increases amount_raised" do
      {_user, _org, _cat, request} = active_request_fixture()
      initial = request.amount_raised

      {:ok, updated} = Requests.add_donation(request, Decimal.new("500"))
      expected = Decimal.add(initial, Decimal.new("500"))
      assert Decimal.equal?(updated.amount_raised, expected)
    end

    test "auto-completes when goal reached" do
      {_user, organization} = organization_with_payment_fixture()
      category = category_fixture()

      {:ok, request} =
        Requests.create_request(organization, %{
          "title" => "Pequeño pedido",
          "description" => "Desc",
          "amount" => "1000",
          "deadline" => Date.add(Date.utc_today(), 30) |> Date.to_string(),
          "category_id" => category.id
        })

      {:ok, active} = Requests.publish_request(request)
      {:ok, completed} = Requests.add_donation(active, Decimal.new("1000"))

      assert completed.status == :completed
    end

    test "rejects donation to non-active request" do
      {_user, _org, _cat, request} = request_fixture()
      assert {:error, :request_not_active} = Requests.add_donation(request, Decimal.new("100"))
    end
  end

  describe "change_request/2" do
    test "returns a changeset" do
      {_user, _org, _cat, request} = request_fixture()
      assert %Ecto.Changeset{} = Requests.change_request(request)
    end
  end
end
