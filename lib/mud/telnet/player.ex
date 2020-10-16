defmodule Mud.Telnet.Player do
  alias Mud.Telnet.{Player, Protocol}
  alias Mud.Actor
  alias Mud.Server, as: MudServer

  defstruct pid: nil

  def start_link(protocol) do
    GenServer.start_link(__MODULE__, protocol)
  end

  def handle_input(player, input) do
    GenServer.cast(player, {:input, input})
  end

  def perceive(player, message) do
    GenServer.cast(player, {:perceive, message})
  end

  # GenServer callbacks
  def init(protocol) do
    send(self(), :welcome_message)
    {:ok, %{protocol: protocol, state: :welcome, actor_id: nil}}
  end

  def handle_cast({:input, input}, state = %{protocol: protocol, state: :get_name}) do
    actor = Actor.new() |> Map.put(:name, input)
    MudServer.add_actor(actor, %Player{pid: self()})
    GenServer.cast(self(), {:input, "look"})
    Protocol.writeline(protocol, "Welcome to the MUD, #{actor.name}!")
    {:noreply, %{state | state: :playing, actor_id: actor.id}}
  end

  def handle_cast({:input, input}, state = %{state: :playing, actor_id: actor_id}) do
    MudServer.handle_input(actor_id, input)
    {:noreply, %{state | state: :playing}}
  end

  def handle_cast({:perceive, message}, state = %{protocol: protocol, state: :playing}) do
    Protocol.writeline(protocol, message)
    {:noreply, state}
  end

  def handle_cast({:input, input}, state = %{protocol: protocol}) do
    Protocol.writeline(protocol, "Echo: #{input}")
    {:noreply, state}
  end

  def handle_info(:welcome_message, state = %{protocol: protocol}) do
    Protocol.write(protocol, "Welcome to the game! What name do you want? ")
    {:noreply, Map.put(state, :state, :get_name)}
  end
end

defimpl Mud.Perceiver, for: Mud.Telnet.Player do
  def perceive(%{pid: pid}, message) do
    Mud.Telnet.Player.perceive(pid, message)
  end
end
