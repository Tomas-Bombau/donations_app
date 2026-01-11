defmodule PuenteAppWeb.PageControllerTest do
  use PuenteAppWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Transforma vidas"
  end
end
