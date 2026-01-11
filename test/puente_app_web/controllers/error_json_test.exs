defmodule PuenteAppWeb.ErrorJSONTest do
  use PuenteAppWeb.ConnCase, async: true

  test "renders 404" do
    assert PuenteAppWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert PuenteAppWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
