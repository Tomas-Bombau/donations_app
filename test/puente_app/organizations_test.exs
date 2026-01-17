defmodule PuenteApp.OrganizationsTest do
  use PuenteApp.DataCase

  alias PuenteApp.Organizations
  alias PuenteApp.Organizations.Organization

  import PuenteApp.AccountsFixtures
  import PuenteApp.OrganizationsFixtures

  describe "register_organization/1" do
    test "creates organization with valid data" do
      user = organization_user_fixture()

      attrs = %{
        organization_name: "Mi Organización",
        organization_role: "presidente",
        province: "CABA",
        user_id: user.id
      }

      assert {:ok, %Organization{} = org} = Organizations.register_organization(attrs)
      assert org.organization_name == "Mi Organización"
      assert org.organization_role == "presidente"
      assert org.province == "CABA"
      assert org.user_id == user.id
    end

    test "returns error changeset with invalid data" do
      assert {:error, %Ecto.Changeset{}} = Organizations.register_organization(%{})
    end

    test "validates organization_role is valid" do
      user = organization_user_fixture()

      attrs = %{
        organization_name: "Mi Organización",
        organization_role: "invalid_role",
        province: "CABA",
        user_id: user.id
      }

      assert {:error, changeset} = Organizations.register_organization(attrs)
      assert "debe seleccionar un rol valido" in errors_on(changeset).organization_role
    end

    test "validates province is valid" do
      user = organization_user_fixture()

      attrs = %{
        organization_name: "Mi Organización",
        organization_role: "presidente",
        province: "Córdoba",
        user_id: user.id
      }

      assert {:error, changeset} = Organizations.register_organization(attrs)
      assert "debe seleccionar una provincia valida" in errors_on(changeset).province
    end

    test "requires municipality for Buenos Aires province" do
      user = organization_user_fixture()

      attrs = %{
        organization_name: "Mi Organización",
        organization_role: "presidente",
        province: "Buenos Aires",
        user_id: user.id
      }

      assert {:error, changeset} = Organizations.register_organization(attrs)
      assert "debe seleccionar un municipio" in errors_on(changeset).municipality
    end

    test "accepts valid Buenos Aires municipality" do
      user = organization_user_fixture()

      attrs = %{
        organization_name: "Mi Organización",
        organization_role: "presidente",
        province: "Buenos Aires",
        municipality: "La Plata",
        user_id: user.id
      }

      assert {:ok, %Organization{} = org} = Organizations.register_organization(attrs)
      assert org.municipality == "La Plata"
    end
  end

  describe "get_organization_by_user_id/1" do
    test "returns organization for existing user" do
      {user, organization} = organization_fixture()
      assert Organizations.get_organization_by_user_id(user.id).id == organization.id
    end

    test "returns nil for non-existing user" do
      assert Organizations.get_organization_by_user_id(Ecto.UUID.generate()) == nil
    end
  end

  describe "update_organization_profile/2" do
    test "updates organization with valid data" do
      {_user, organization} = organization_fixture()

      attrs = %{
        address: "Nueva Dirección 456",
        cbu: "1234567890123456789012"
      }

      assert {:ok, %Organization{} = updated} =
               Organizations.update_organization_profile(organization, attrs)

      assert updated.address == "Nueva Dirección 456"
      assert updated.cbu == "1234567890123456789012"
    end

    test "validates CBU format" do
      {_user, organization} = organization_fixture()

      attrs = %{
        address: "Nueva Dirección",
        cbu: "invalid"
      }

      assert {:error, changeset} = Organizations.update_organization_profile(organization, attrs)
      assert "debe tener 22 digitos numericos" in errors_on(changeset).cbu
    end

    test "accepts payment_alias instead of CBU" do
      {_user, organization} = organization_fixture()

      attrs = %{
        address: "Nueva Dirección",
        payment_alias: "mi.alias.mp"
      }

      assert {:ok, %Organization{} = updated} =
               Organizations.update_organization_profile(organization, attrs)

      assert updated.payment_alias == "mi.alias.mp"
    end
  end

  describe "update_organization_social/2" do
    test "updates social media fields" do
      {_user, organization} = organization_fixture()

      attrs = %{
        facebook: "https://facebook.com/miorg",
        instagram: "https://instagram.com/miorg"
      }

      assert {:ok, %Organization{} = updated} =
               Organizations.update_organization_social(organization, attrs)

      assert updated.facebook == "https://facebook.com/miorg"
      assert updated.instagram == "https://instagram.com/miorg"
    end
  end

  describe "change_organization_profile/2" do
    test "returns a changeset" do
      {_user, organization} = organization_fixture()
      assert %Ecto.Changeset{} = Organizations.change_organization_profile(organization)
    end
  end

  describe "change_organization_social/2" do
    test "returns a changeset" do
      {_user, organization} = organization_fixture()
      assert %Ecto.Changeset{} = Organizations.change_organization_social(organization)
    end
  end

  describe "has_payment_configured?/1" do
    test "returns false when no payment info" do
      {_user, organization} = organization_fixture()
      refute Organization.has_payment_configured?(organization)
    end

    test "returns true when CBU is set" do
      {_user, organization} = organization_with_payment_fixture()
      assert Organization.has_payment_configured?(organization)
    end

    test "returns true when payment_alias is set" do
      {_user, organization} = organization_fixture()

      {:ok, org} =
        Organizations.update_organization_profile(organization, %{
          address: "Calle 123",
          payment_alias: "mi.alias"
        })

      assert Organization.has_payment_configured?(org)
    end
  end
end
