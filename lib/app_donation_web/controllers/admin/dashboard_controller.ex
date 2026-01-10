defmodule AppDonationWeb.Admin.DashboardController do
  use AppDonationWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
