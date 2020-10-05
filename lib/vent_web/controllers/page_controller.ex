defmodule VentWeb.PageController do
  use VentWeb, :controller
  import Ecto.Changeset
  alias Vent.{ChatServer, ChatFormInput}
  @room_id_length 10

  def index(conn, _params) do
    changeset = ChatFormInput.new_changeset(%ChatFormInput{})
    render(conn, "index.html", changeset: changeset)
  end

  def new_room(conn, _params) do
    render(conn, "change_room.html")
  end

  def change_room(conn, %{"role" => "vent"} = _params) do
    user_id = get_session(conn, :user_id)
    username = get_session(conn, :username)

    # get current room_id from session to ensure user isn't potentially put back into same room they just left
    current_room_id = get_session(conn, :current_room_id)
    room_id = check_vent_openings(current_room_id)

    process_additional_chat_request(conn, room_id, username, "vent", user_id)
  end

  def change_room(conn, %{"role" => "listen"} = _params) do
    user_id = get_session(conn, :user_id)
    username = get_session(conn, :username)

    # get current room_id from session to ensure user isn't potentially put back into same room they just left
    current_room_id = get_session(conn, :current_room_id)
    room_id = check_listen_openings(current_room_id)

    process_additional_chat_request(conn, room_id, username, "listen", user_id)
  end

  def chat(
        conn,
        %{"chat_form_input" => %{"name" => username} = form_input, "vent" => ""} = _params
      ) do
    changeset = ChatFormInput.validate_changeset(%ChatFormInput{}, form_input)

    case apply_action(changeset, :insert) do
      {:ok, _data} ->
        IO.puts("HIT VENT")

        # pass in empty string since this is their first connection to any room. a room id is passed to ensure that if someone tries to change
        # rooms while keeping the same role, they won't be put back in the room they just left
        room_id = check_vent_openings("")
        process_initial_chat_request(conn, room_id, username, "vent")

      {:error, changeset} ->
        render(conn, "index.html", changeset: changeset)
    end
  end

  def chat(
        conn,
        %{"chat_form_input" => %{"name" => username} = form_input, "listen" => ""} = _params
      ) do
    changeset = ChatFormInput.validate_changeset(%ChatFormInput{}, form_input)

    case apply_action(changeset, :insert) do
      {:ok, _data} ->
        IO.puts("HIT LISTEN")

        # pass in empty string since this is their first connection to any room. a room id is passed to ensure that if someone tries to change
        # rooms while keeping the same role, they won't be put back in the room they just left
        room_id = check_listen_openings("")
        process_initial_chat_request(conn, room_id, username, "listen")

      {:error, changeset} ->
        render(conn, "index.html", changeset: changeset)
    end
  end

  def process_initial_chat_request(conn, room_id, name, role) do
    IO.puts("In process request!")
    fake_user_id = create_user_id()

    conn
    |> assign(:auth_token, generate_auth_token(conn, fake_user_id))
    |> assign(:user_id, fake_user_id)
    |> assign(:room_id, room_id)
    |> assign(:username, name)
    |> assign(:role, role)
    |> put_session(:user_id, fake_user_id)
    |> put_session(:username, name)
    |> put_session(:current_room_id, room_id)
    |> render("chat.html")
  end

  def process_additional_chat_request(conn, room_id, name, role, user_id) do
    IO.puts("In additional process request!")

    conn
    |> assign(:auth_token, generate_auth_token(conn, user_id))
    |> assign(:user_id, user_id)
    |> assign(:room_id, room_id)
    |> assign(:username, name)
    |> assign(:role, role)
    |> render("chat.html")
  end

  def check_vent_openings(current_room_id) do
    case ChatServer.check_vent_openings(current_room_id) do
      [] ->
        IO.puts("NO VENT OPENINGS")
        create_room_for_vent()

      room_id ->
        IO.puts("VENT OPENING: #{room_id}")
        room_id
    end
  end

  def check_listen_openings(current_room_id) do
    case ChatServer.check_listen_openings(current_room_id) do
      [] ->
        IO.puts("NO LISTEN OPENINGS")
        create_room_for_listen()

      room_id ->
        IO.puts("LISTEN OPENING: #{room_id}")
        room_id
    end
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
    :crypto.strong_rand_bytes(@room_id_length)
    |> Base.encode64()
    |> binary_part(0, @room_id_length)
  end

  defp generate_auth_token(conn, user_id) do
    Phoenix.Token.sign(conn, "salt identifier", user_id)
  end
end
