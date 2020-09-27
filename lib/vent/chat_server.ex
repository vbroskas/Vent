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

  def left_room(room_id) do
    GenServer.call(@name, {:left_room, room_id})
  end

  def check_rooms() do
    GenServer.call(@name, :check_table)
  end

  def add_room(room_id) do
    GenServer.cast(@name, {:new_room, room_id})
  end

  def handle_call({:left_room, id}, _from, state) do
    IO.puts("IN LEFT ROOM HANDLE CALL")
    IO.puts(id)
    # query room by id get count & room_id
    func =
      fun do
        {room_id, count} when room_id == ^id -> {room_id, count}
      end

    result = :ets.select(:chat_table, func)
    IO.inspect(result)

    [{room_id, count}] = :ets.select(:chat_table, func)

    case count - 1 do
      1 ->
        IO.puts("down to 1")
        :ets.insert(:chat_table, {room_id, 1})

      0 ->
        IO.puts("TOPIC DELETED")
        :ets.delete(:chat_table, room_id)
    end

    IO.puts("FINISHING UP+++++")
    {:reply, :ok, state}

    # subtract 1 from count.
    # if count now 1, insert room with new count
    # if count 0, delete row from ets
  end

  def handle_call(:check_table, _from, state) do
    # query ETS for any open rooms
    fun =
      fun do
        {room_id, count} when count < 2 -> room_id
      end

    result =
      case :ets.select(:chat_table, fun) do
        # grab first empty room
        result when result != [] ->
          room_id = List.first(result)
          :ets.insert(:chat_table, {room_id, 2})
          room_id

        # no empty rooms found
        [] ->
          []
      end

    # if open room found increase count for that room, and return room_id to controller
    # if no room found, return [] to controller
    {:reply, result, state}
  end

  def handle_cast({:new_room, room_id}, state) do
    :ets.insert(:chat_table, {room_id, 1})
    {:noreply, state}
  end
end
