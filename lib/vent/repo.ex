defmodule Vent.Repo do
  use Ecto.Repo,
    otp_app: :vent,
    adapter: Ecto.Adapters.Postgres
end
