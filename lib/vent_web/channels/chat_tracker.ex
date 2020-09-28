defmodule VentWeb.ChatTracker do
  @behaviour Phoenix.Tracker
  alias Vent.ChatServer

  require Logger

  @doc """
  This module is mostly boilerplate that can be reused in other projects. The
  start_link/1 function sets up default options that are then passed into
  Phoenix.Tracker.start_link/3. The Tracker process is then started—it supervises a
  collection of Phoenix.Tracker.Shard processes. The init/1 function is called for each
  Shard that is created. We must provide the pubsub_server key in the init/1 function,
  or the Tracker will crash.
  """

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts) do
    opts =
      opts
      |> Keyword.put(:name, __MODULE__)
      |> Keyword.put(:pubsub_server, Vent.PubSub)

    Phoenix.Tracker.start_link(__MODULE__, opts, opts)
  end

  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server}}
  end

  @doc """
  Tracker requires that a handle_diff/2 function is implemented. This is where you
  perform logic based on the changes in state. Let’s implement a handle_diff/2
  function that prints out the changes.
  """

  def handle_diff(diff, state) do
    for {topic, {joins, leaves}} <- diff do
      # Logger.info(inspect(topic))
      # Logger.info(inspect(joins))
      # Logger.info(inspect(leaves))

      # user left a topic, make call to chat server
      if leaves != [] do
        <<"chat:", rest::binary>> = topic
        ChatServer.left_room(rest)
      end

      # result = list(topic)
      # for {key, meta} <- joins do
      #   IO.puts("#{topic}~~presence join: key \"#{key}\" with meta #{inspect(meta)}")
      #   msg = {:join, key, meta}
      #   # Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      # end

      # for {key, meta} <- leaves do
      #   IO.puts("#{topic}~~presence leave: key \"#{key}\" with meta #{inspect(meta)}")
      #   msg = {:leave, key, meta}
      #   # Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      # end
    end

    {:ok, state}
  end

  @doc """
  Phoenix.Tracker.track/5 is the most important call for our Tracker. This will take
  a pid and track it for a given topic. Any metadata can be provided here, which
  is useful for knowing who is connected and when they joined.
  """
  def track(%{channel_pid: pid, topic: topic, assigns: %{user_id: user_id}}) do
    metadata = %{
      online_at: DateTime.utc_now(),
      user_id: user_id
    }

    Phoenix.Tracker.track(__MODULE__, pid, topic, user_id, metadata)
  end

  def list(topic) do
    Phoenix.Tracker.list(__MODULE__, topic)
  end

  def get_all_rows() do
    :ets.tab2list(:chat_table)
  end
end
