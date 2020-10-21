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

  def perceive(player, message) do
    GenServer.cast(player, {:perceive, message})
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

  def handle_cast(
        {:perceive, {Mud.Command.Look, room}},
        state = %{protocol: protocol, state: :playing}
      ) do
    message = "#{room.name}\r\n#{room.description}\r\n"
    Protocol.writeline(protocol, message)
    {:noreply, state}
  end

  def handle_cast(
        {:perceive, {Mud.Command.Quit, :success}},
        state = %{actor_id: actor_id, protocol: protocol, state: :playing}
      ) do
    message = "You quit.\r\n"
    Protocol.writeline(protocol, message)
    Logger.info("Player [#{actor_id}] from ip [#{Protocol.ip(protocol)}] quit.")
    Protocol.disconnect(protocol)
    {:stop, :normal, state}
  end

  def handle_cast(
        {:perceive, {Mud.Command.Quit, :failure}},
        state = %{protocol: protocol, state: :playing}
      ) do
    message = "You must type 'quit' to quit.\r\n"
    Protocol.writeline(protocol, message)
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
