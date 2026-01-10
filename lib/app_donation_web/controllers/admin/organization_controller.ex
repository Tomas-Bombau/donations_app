defmodule AppDonationWeb.Admin.ManageOrganizationController do
  use AppDonationWeb, :controller

  alias AppDonation.Accounts

  def show(conn, %{"id" => id}) do
    organization = Accounts.get_user_with_profile!(id)
    render(conn, :show, organization: organization)
  end
end
