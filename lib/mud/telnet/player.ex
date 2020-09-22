defmodule Mud.Telnet.Player do
  alias Mud.Telnet.Protocol

  def start_link(protocol) do
    GenServer.start_link(__MODULE__, protocol)
  end

  def handle_input(player, input) do
    GenServer.cast(player, {:input, input})
  end

  # GenServer callbacks
  def init(protocol) do
    {:ok, %{protocol: protocol, state: :welcome}}
  end

  def handle_cast({:input, input}, state = %{protocol: protocol}) do
    Protocol.write(protocol, "Echo: #{input}")
    {:noreply, state}
  end
end
