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
        {room_id, count, time} when room_id == ^id -> {room_id, count}
      end

    [{room_id, count}] = :ets.select(:chat_table, func)

    case count - 1 do
      1 ->
        IO.puts("down to 1")
        :ets.insert(:chat_table, {room_id, 1, create_timestamp()})

      0 ->
        IO.puts("TOPIC DELETED")
        :ets.delete(:chat_table, room_id)
    end

    IO.puts("FINISHING UP+++++")
    {:reply, :ok, state}
  end

  # TODO, make two versions of this function to check for
  # vent opening and listen opening
  def handle_call(:check_table, _from, state) do
    # query ETS for any open rooms
    fun =
      fun do
        {room_id, count, time} when count < 2 -> {room_id, time}
      end

    result =
      case :ets.select(:chat_table, fun) do
        # no empty rooms found
        [] ->
          []

        # get room that's been empty the longest
        result when result != [] ->
          {room_id, _} = Enum.min_by(result, fn {_k, v} -> v end)
          # get open room that has been waiting the longest
          :ets.insert(:chat_table, {room_id, 2, create_timestamp()})
          room_id
      end

    {:reply, result, state}
  end

  def create_timestamp() do
    DateTime.to_unix(DateTime.utc_now())
  end

  # TODO need to create :new_room_vent and :new_room_listen to start rooms
  # with either vent or listen set to 1
  def handle_cast({:new_room, room_id}, state) do
    :ets.insert(:chat_table, {room_id, 1, create_timestamp()})
    {:noreply, state}
  end
end
