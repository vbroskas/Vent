defmodule VentWeb.PageController do
  use VentWeb, :controller
  alias Vent.ChatServer

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def chat(conn, params) do
    # check ETS for any open rooms
    room_id =
      case ChatServer.check_rooms() do
        [] -> create_room_id(10)
        room_id -> room_id
      end

    fake_user_id = create_user_id()

    conn
    |> assign(:auth_token, generate_auth_token(conn, fake_user_id))
    |> assign(:user_id, fake_user_id)
    |> assign(:room_id, room_id)
    |> assign(:username, params["name"])
    |> render("chat.html")
  end

  defp create_user_id() do
    Enum.random(1_000..9_999)
  end

  defp create_room_id(length) do
    room_id = :crypto.strong_rand_bytes(length) |> Base.encode64() |> binary_part(0, length)
    ChatServer.add_room(room_id)
    room_id
  end

  defp generate_auth_token(conn, user_id) do
    Phoenix.Token.sign(conn, "salt identifier", user_id)
  end
end
