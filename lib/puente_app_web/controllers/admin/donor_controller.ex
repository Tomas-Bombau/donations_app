defmodule PuenteAppWeb.Admin.ManageDonorController do
  use PuenteAppWeb, :controller

  alias PuenteApp.Accounts

  def show(conn, %{"id" => id}) do
    donor = Accounts.get_user_with_profile!(id)
    render(conn, :show, donor: donor)
  end
end
