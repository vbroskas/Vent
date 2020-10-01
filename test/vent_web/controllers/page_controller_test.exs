defmodule VentWeb.PageControllerTest do
  use VentWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Vent"
  end
end
