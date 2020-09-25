defmodule VentWeb.ChatChannel do
  use Phoenix.Channel
  alias Vent.ChatPresence
  require Logger

  def join(
        "chat:" <> room_id,
        _payload,
        socket = %{assigns: %{user_id: user_id, username: username}}
      ) do
    send(self(), :after_join)
    {:ok, %{user_id: user_id, username: username, room_id: room_id}, socket}
  end

  def handle_info(
        :after_join,
        %{channel_pid: pid, topic: topic, assigns: %{user_id: user_id}} = socket
      ) do
    metadata = %{
      online_at: DateTime.utc_now(),
      user_id: user_id
    }

    IO.puts("#####PRESSENCE######")
    IO.inspect(socket)

    ChatPresence.track(pid, topic, user_id, metadata)
    # Presence.track(socket, socket.assigns.user_id, )
    {:noreply, socket}
  end
end
