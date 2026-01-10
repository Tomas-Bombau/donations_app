defmodule AppDonationWeb.PageController do
  use AppDonationWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
