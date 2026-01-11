defmodule PuenteAppWeb.Admin.MetricsController do
  use PuenteAppWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
