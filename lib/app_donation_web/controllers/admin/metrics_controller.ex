defmodule AppDonationWeb.Admin.MetricsController do
  use AppDonationWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
