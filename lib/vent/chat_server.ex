defmodule Vent.ChatServer do
  use GenServer, restart: :transient
  import Ex2ms

  @name :chat_server

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  def init(state) do
    IO.puts("CHAT SERVER STARTED")
    # start ETS
    :ets.new(:chat_table, [:set, :protected, :named_table])

    {:ok, state}
  end

  def check_rooms() do
    IO.puts("_________in check rooms func")
    GenServer.call(@name, :check_table)
  end

  def add_room(room_id) do
    GenServer.cast(@name, {:new_room, room_id})
  end

  def handle_call(:check_table, _from, state) do
    IO.puts("_________Handle call check_table")
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
