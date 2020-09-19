defmodule Mud.Game.WorldServer do
  use GenServer
  require Logger

  def start_link() do
    Logger.info("World starting.")
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  # GenServer callbacks
  def init(_args) do
    {:ok, nil}
  end
end
