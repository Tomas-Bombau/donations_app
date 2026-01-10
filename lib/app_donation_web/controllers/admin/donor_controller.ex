defmodule AppDonationWeb.Admin.ManageDonorController do
  use AppDonationWeb, :controller

  alias AppDonation.Accounts

  def show(conn, %{"id" => id}) do
    donor = Accounts.get_user_with_profile!(id)
    render(conn, :show, donor: donor)
  end
end
