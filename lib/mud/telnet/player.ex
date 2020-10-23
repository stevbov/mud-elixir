defmodule Mud.Telnet.Player do
  alias Mud.Telnet.{Player, Protocol}
  alias Mud.Actor
  require Logger

  defstruct pid: nil

  def start_link(protocol) do
    GenServer.start_link(__MODULE__, protocol)
  end

  def handle_input(player, input) do
    GenServer.cast(player, {:input, input})
  end

  def perceive(player, act, role, situation) do
    GenServer.cast(player, {:perceive, act, role, situation})
  end

  # GenServer callbacks
  def init(protocol) do
    send(self(), :welcome_message)
    {:ok, %{protocol: protocol, state: :welcome, actor_id: nil}}
  end

  def handle_cast({:input, input}, state = %{protocol: protocol, state: :get_name}) do
    actor = Actor.new(%Player{pid: self()}) |> Map.put(:name, input)
    Mud.CommandDispatcher.add_actor(actor)
    GenServer.cast(self(), {:input, "look"})
    Protocol.writeline(protocol, "Welcome to the MUD, #{actor.name}!")
    {:noreply, %{state | state: :playing, actor_id: actor.id}}
  end

  def handle_cast(
        {:input, input},
        state = %{protocol: protocol, state: :playing, actor_id: actor_id}
      ) do
    if String.trim(input) != "" do
      case Mud.Command.parse_command(input) do
        {:ok, {module, args}} ->
          Mud.CommandDispatcher.dispatch(actor_id, module, args)

        _ ->
          Protocol.writeline(protocol, "Huh!?")
      end
    end

    {:noreply, state}
  end

  def handle_cast({:perceive, Mud.Command.Look, :actor, situation}, state = %{protocol: protocol, state: :playing}) do
    actors_str = situation.room.actors
    |> Enum.filter(fn actor -> actor.id != situation.actor.id end)
    |> Enum.map(fn actor -> "You see #{actor.name} standing here.\r\n" end)

    Protocol.writeline(protocol, "#{situation.room.name}\r\n#{situation.room.description}\r\n#{actors_str}")
    {:noreply, state}
  end

  def handle_cast(
        {:perceive, {Mud.Command.Quit, :success}, role, situation},
        state = %{actor_id: actor_id, protocol: protocol, state: :playing}
      ) do
    case role do
      :actor ->
        Protocol.writeline(protocol, "You quit.")
        Logger.info("Player [#{actor_id}] from ip [#{Protocol.ip(protocol)}] quit.")
        Protocol.disconnect(protocol)
        {:stop, :normal, state}
      _ ->
        Protocol.writeline(protocol, "#{situation.actor.name} quits.")
        {:noreply, state}
    end
  end

  def handle_cast(
        {:perceive, {Mud.Command.Quit, :failure}, :actor, _situation},
        state = %{protocol: protocol, state: :playing}
      ) do
    Protocol.writeline(protocol, "You must type 'quit' to quit.")
    {:noreply, state}
  end

  def handle_cast({:perceive, action, role}, state) do
    Logger.error("Mud.Player.perceive - unhandled action #{inspect action}, role #{inspect role}")
    {:noreply, state}
  end

  def handle_info(:welcome_message, state = %{protocol: protocol}) do
    Protocol.write(protocol, "Welcome to the game! What name do you want? ")
    {:noreply, Map.put(state, :state, :get_name)}
  end
end

defimpl Mud.Perceiver, for: Mud.Telnet.Player do
  def perceive(%{pid: pid}, act, role, situation) do
    Mud.Telnet.Player.perceive(pid, act, role, situation)
  end
end
