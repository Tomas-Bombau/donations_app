defmodule PuenteAppWeb.PageController do
  use PuenteAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
