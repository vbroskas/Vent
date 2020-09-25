defmodule Vent.ChatPresence do
  use Phoenix.Presence,
    otp_app: :my_app,
    pubsub_server: Vent.PubSub
end
