defmodule Vent.ChatSupervisor do
  use Supervisor
  alias Vent.ChatServer

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    IO.puts("SUPERVISOR STARTED")

    children = [
      ChatServer
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
