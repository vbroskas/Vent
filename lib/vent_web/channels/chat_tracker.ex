defmodule VentWeb.ChatTracker do
  @behaviour Phoenix.Tracker
  alias Vent.ChatServer

  require Logger

  @doc """
  track all clients connected to each "chat:subtopic"
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
  on each leaves event make call to genserver
  """

  def handle_diff(diff, state) do
    for {topic, {joins, leaves}} <- diff do
      # Logger.info(inspect(topic))
      # Logger.info(inspect(joins))
      # Logger.info(inspect(leaves))
      <<"chat:", sub_topic::binary>> = topic

      for {key, meta} <- leaves do
        IO.puts("#{sub_topic}~~role: #{meta.role} user: #{key}")
        ChatServer.left_room(sub_topic, meta.role)
        # msg = {:leave, key, meta}
        # Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      end

      for {key, meta} <- joins do
        IO.puts("#{sub_topic}~~presence join: key \"#{key}\" with meta #{inspect(meta)}")
        # msg = {:join, key, meta}
        # Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      end
    end

    {:ok, state}
  end

  @doc """
  track user_id and their role
  """
  def track(%{channel_pid: pid, topic: topic, assigns: %{user_id: user_id, role: role}}) do
    metadata = %{
      online_at: DateTime.utc_now(),
      user_id: user_id,
      role: role
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
