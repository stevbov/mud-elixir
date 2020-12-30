defmodule Mud.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @default_port 5500

  use Application

  def start(_type, _args) do
    children = [
      {Mud.Telnet.Listener, [@default_port]},
      {Registry, keys: :unique, name: Mud.RoomServer.Registry},
      {Mud.WorldServer, []}
    ]

    opts = [strategy: :one_for_one, name: Mud.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
