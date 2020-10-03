defmodule VentWeb.ChatChannel do
  use Phoenix.Channel
  alias Vent.ChatPresence
  alias VentWeb.ChatTracker
  require Logger

  def join(
        "chat:" <> room_id,
        _payload,
        socket = %{assigns: %{user_id: user_id, username: username}}
      ) do
    send(self(), :after_join)
    {:ok, %{user_id: user_id, username: username, room_id: room_id}, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    IO.puts("````````````````")
    IO.inspect(socket)
    broadcast!(socket, "new_msg", %{body: body, username: socket.assigns.username})
    {:noreply, socket}
  end

  @doc """
  know when each user is typing
  """
  def handle_in(
        "user:typing",
        %{"typing" => typing},
        %{channel_pid: pid, topic: topic, assigns: %{user_id: user_id, username: username}} =
          socket
      ) do
    metadata = %{
      online_at: DateTime.utc_now(),
      user_id: user_id,
      username: username,
      typing: typing
    }

    {:ok, _} = ChatPresence.update(pid, topic, user_id, metadata)

    {:reply, :ok, socket}
  end

  @doc """
  after channel join, start pubsub tracker and phoenix presence.
  """
  def handle_info(
        :after_join,
        %{channel_pid: pid, topic: topic, assigns: %{user_id: user_id, username: username}} =
          socket
      ) do
    # Pubsub tracker--
    {:ok, _} = ChatTracker.track(socket)

    # Presence tracker--
    metadata = %{
      online_at: DateTime.utc_now(),
      user_id: user_id,
      username: username
    }

    {:ok, _} = ChatPresence.track(pid, topic, user_id, metadata)
    push(socket, "presence_state", ChatPresence.list(socket))
    {:noreply, socket}
  end

  # intercept ["presence_diff"]

  def handle_out("presence_diff", msg, socket) do
    IO.puts("````````````````````")
    IO.inspect(msg)
    {:noreply, socket}
  end
end
