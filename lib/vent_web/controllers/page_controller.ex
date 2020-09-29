defmodule VentWeb.PageController do
  use VentWeb, :controller
  alias Vent.ChatServer
  @room_id_length 10

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def chat(conn, %{"vent" => "", "name" => name} = _params) do
    IO.puts("HIT VENT")

    room_id =
      case check_vent_openings() do
        [] ->
          IO.puts("NO VENT OPENINGS")
          create_room_for_vent()

        room_id ->
          IO.puts("VENT OPENING?? #{room_id}")
          room_id
      end

    process_chat_request(conn, room_id, name, "vent")
  end

  def chat(conn, %{"listen" => "", "name" => name} = _params) do
    IO.puts("HIT LISTEN")

    room_id =
      case check_listen_openings() do
        [] ->
          IO.puts("NO LISTEN OPENINGS")
          create_room_for_listen()

        room_id ->
          room_id
      end

    process_chat_request(conn, room_id, name, "listen")
  end

  def process_chat_request(conn, room_id, name, role) do
    IO.puts("In process request!")
    fake_user_id = create_user_id()

    conn
    |> assign(:auth_token, generate_auth_token(conn, fake_user_id))
    |> assign(:user_id, fake_user_id)
    |> assign(:room_id, room_id)
    |> assign(:username, name)
    |> assign(:role, role)
    |> render("chat.html")
  end

  def check_vent_openings() do
    ChatServer.check_vent_openings()
  end

  def check_listen_openings() do
    ChatServer.check_listen_openings()
  end

  defp create_user_id() do
    Enum.random(1_000..9_999)
  end

  defp create_room_for_vent() do
    room_id = create_room_id()
    ChatServer.create_room_for_vent(room_id)
    room_id
  end

  defp create_room_for_listen() do
    room_id = create_room_id()
    ChatServer.create_room_for_listen(room_id)
    room_id
  end

  defp create_room_id() do
    room_id =
      :crypto.strong_rand_bytes(@room_id_length)
      |> Base.encode64()
      |> binary_part(0, @room_id_length)
  end

  defp generate_auth_token(conn, user_id) do
    Phoenix.Token.sign(conn, "salt identifier", user_id)
  end
end
