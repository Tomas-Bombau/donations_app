defmodule PuenteAppWeb.Admin.DashboardController do
  use PuenteAppWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
