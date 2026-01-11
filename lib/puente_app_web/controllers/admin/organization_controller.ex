defmodule PuenteAppWeb.Admin.ManageOrganizationController do
  use PuenteAppWeb, :controller

  alias PuenteApp.Accounts

  def show(conn, %{"id" => id}) do
    organization = Accounts.get_user_with_profile!(id)
    render(conn, :show, organization: organization)
  end
end
