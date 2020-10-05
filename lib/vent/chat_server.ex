defmodule Vent.ChatServer do
  use GenServer, restart: :transient
  import Ex2ms

  @name :chat_server

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  def init(state) do
    :ets.new(:chat_table, [:set, :protected, :named_table])

    {:ok, state}
  end

  def left_room(room_id, role) do
    GenServer.call(@name, {:left_room, room_id, role})
  end

  def check_vent_openings(current_room_id) do
    GenServer.call(@name, {:check_vent_openings, current_room_id})
  end

  def check_listen_openings(current_room_id) do
    GenServer.call(@name, {:check_listen_openings, current_room_id})
  end

  def create_room_for_vent(room_id) do
    GenServer.cast(@name, {:create_room_for_vent, room_id})
  end

  def create_room_for_listen(room_id) do
    GenServer.cast(@name, {:create_room_for_listen, room_id})
  end

  @doc """
  when listen user leaves a subtopic, pattern match on their role.
  """
  def handle_call({:left_room, id, _role = "listen"}, _from, state) do
    IO.puts("LISTEN LEFT ROOOOM")
    IO.puts(id)
    # query room by id get count & room_id
    [{room_id, vent, _listen}] = left_room_query(id)

    cond do
      vent == 1 ->
        IO.puts("Vent remaining")
        :ets.insert(:chat_table, {room_id, vent, 0, create_timestamp()})

      vent == 0 ->
        IO.puts("TOPIC DELETED")
        :ets.delete(:chat_table, room_id)
    end

    {:reply, :ok, state}
  end

  @doc """
  when vent user leaves a subtopic, pattern match on their role.
  """
  def handle_call({:left_room, id, _role = "vent"}, _from, state) do
    IO.puts("VENT LEFT ROOM")
    IO.puts(id)
    # query room by id get count & room_id
    [{room_id, _vent, listen}] = left_room_query(id)

    cond do
      listen == 1 ->
        IO.puts("Listener remaining")
        :ets.insert(:chat_table, {room_id, 0, listen, create_timestamp()})

      listen == 0 ->
        IO.puts("TOPIC DELETED")
        :ets.delete(:chat_table, room_id)
    end

    {:reply, :ok, state}
  end

  @doc """
  Find rooms with vent openings
  """
  def handle_call({:check_vent_openings, current_room_id}, _from, state) do
    result =
      case query_vent_openings(current_room_id) do
        # no empty rooms found
        [] ->
          []

        result ->
          # get open room that has been waiting the longest
          {room_id, _vent, listen, _time} = Enum.min_by(result, fn {_id, _v, _l, t} -> t end)
          :ets.insert(:chat_table, {room_id, 1, listen, create_timestamp()})
          room_id
      end

    {:reply, result, state}
  end

  @doc """
  Find rooms with listen openings
  ets row pattern is {room_id, vent_number, listen_number, timestamp}
  """
  def handle_call({:check_listen_openings, current_room_id}, _from, state) do
    result =
      case query_listen_openings(current_room_id) do
        # no empty rooms found
        [] ->
          []

        result ->
          # get open room that has been waiting the longest
          {room_id, vent, _listen, _time} = Enum.min_by(result, fn {_id, _v, _l, t} -> t end)
          # update record for that room with new listener
          :ets.insert(:chat_table, {room_id, vent, 1, create_timestamp()})
          room_id
      end

    {:reply, result, state}
  end

  def create_timestamp() do
    DateTime.to_unix(DateTime.utc_now())
  end

  @doc """
  ets row pattern is {room_id, vent_number, listen_number, timestamp}
  create new room with just a vent subscribed
  """
  def handle_cast({:create_room_for_vent, room_id}, state) do
    :ets.insert(:chat_table, {room_id, 1, 0, create_timestamp()})
    {:noreply, state}
  end

  @doc """
  ets row pattern is {room_id, vent_number, listen_number, timestamp}
  create new room with just a listener subscribed
  """
  def handle_cast({:create_room_for_listen, room_id}, state) do
    :ets.insert(:chat_table, {room_id, 0, 1, create_timestamp()})
    {:noreply, state}
  end

  defp query_vent_openings(current_room_id) do
    fun =
      fun do
        {room_id, vent, listen, time} when vent == 0 and room_id != ^current_room_id ->
          {room_id, vent, listen, time}
      end

    :ets.select(:chat_table, fun)
  end

  defp query_listen_openings(current_room_id) do
    fun =
      fun do
        {room_id, vent, listen, time} when listen == 0 and room_id != ^current_room_id ->
          {room_id, vent, listen, time}
      end

    :ets.select(:chat_table, fun)
  end

  @doc """
  ets query for when client leaves a subtopic. find the room they left by room_id
  """
  defp left_room_query(id) do
    func =
      fun do
        {room_id, vent, listen, time} when room_id == ^id -> {room_id, vent, listen}
      end

    :ets.select(:chat_table, func)
  end
end
