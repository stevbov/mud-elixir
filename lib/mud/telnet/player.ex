defmodule Mud.Telnet.Player do
  alias Mud.Telnet.{Player, Protocol}
  alias Mud.{Actor, Command, WorldServer}
  require Logger

  defstruct pid: nil

  @spec start_link(pid) :: {:ok, pid}
  def start_link(protocol) do
    GenServer.start_link(__MODULE__, protocol)
  end

  @spec handle_input(pid, String.t()) :: :ok
  def handle_input(pid, input) do
    GenServer.cast(pid, {:input, input})
  end

  def quit(pid) do
    GenServer.cast(pid, :quit)
  end

  def writeline(pid, message) do
    GenServer.cast(pid, {:writeline, message})
  end

  def write(pid, message) do
    GenServer.cast(pid, {:write, message})
  end

  # GenServer callbacks
  def init(protocol) do
    send(self(), :welcome_message)
    {:ok, %{protocol: protocol, state: :welcome, actor_id: nil}}
  end

  def handle_cast({:input, input}, state = %{protocol: protocol, state: :get_name}) do
    actor = Actor.new(%Player{pid: self()}) |> Map.put(:name, input)

    actor = %{
      actor
      | inventory: [Actor.new(Mud.Npc.new()) |> Map.put(:name, "a sword") | actor.inventory]
    }

    actor = %{
      actor
      | inventory: [Actor.new(Mud.Npc.new()) |> Map.put(:name, "a shield") | actor.inventory]
    }

    actor = %{
      actor
      | inventory: [
          Actor.new(Mud.Npc.new()) |> Map.put(:name, "a shirt of chain mail") | actor.inventory
        ]
    }

    actor = %{
      actor
      | inventory: [
          Actor.new(Mud.Npc.new()) |> Map.put(:name, "a hard leather cuirass") | actor.inventory
        ]
    }

    actor = %{
      actor
      | inventory: [
          Actor.new(Mud.Npc.new()) |> Map.put(:name, "a pair of shoes") | actor.inventory
        ]
    }

    actor = %{
      actor
      | inventory: [
          Actor.new(Mud.Npc.new()) |> Map.put(:name, "a pair of pants") | actor.inventory
        ]
    }

    actor = %{
      actor
      | inventory: [
          Actor.new(Mud.Npc.new()) |> Map.put(:name, "a pair of steel gauntlets")
          | actor.inventory
        ]
    }

    actor = %{
      actor
      | inventory: [
          Actor.new(Mud.Npc.new()) |> Map.put(:name, "a pair of steel greaves") | actor.inventory
        ]
    }

    actor = %{
      actor
      | inventory: [
          Actor.new(Mud.Npc.new()) |> Map.put(:name, "a steel gorget") | actor.inventory
        ]
    }

    actor = %{
      actor
      | inventory: [Actor.new(Mud.Npc.new()) |> Map.put(:name, "a steel visor") | actor.inventory]
    }

    actor = %{
      actor
      | inventory: [
          Actor.new(Mud.Npc.new()) |> Map.put(:name, "a steel helmet") | actor.inventory
        ]
    }

    actor = %{
      actor
      | inventory: [
          Actor.new(Mud.Npc.new()) |> Map.put(:name, "a pair of steel vambraces")
          | actor.inventory
        ]
    }

    actor = %{
      actor
      | inventory: [Actor.new(Mud.Npc.new()) |> Map.put(:name, "a black cloak") | actor.inventory]
    }

    chest_inventory =
      for _n <- 1..3000, do: Actor.new(Mud.Npc.new()) |> Map.put(:name, "a loaf of bread")

    chest =
      Actor.new(Mud.Npc.new())
      |> Map.put(:name, "a backpack of holding")
      |> Map.put(:inventory, chest_inventory)

    actor = %{actor | inventory: [chest | actor.inventory]}

    WorldServer.add_actor(actor)
    GenServer.cast(self(), {:input, "look"})
    Protocol.writeline(protocol, "Welcome to the MUD, #{actor.name}!")
    {:noreply, %{state | state: :playing, actor_id: actor.id}}
  end

  def handle_cast(
        {:input, input},
        state = %{protocol: protocol, state: :playing, actor_id: actor_id}
      ) do
    if String.trim(input) != "" do
      if Command.execute(actor_id, input) == :invalid do
        Protocol.writeline(protocol, "Huh!?")
      end
    end

    {:noreply, state}
  end

  def handle_cast({:write, message}, state = %{protocol: protocol}) do
    Protocol.write(protocol, message)
    {:noreply, state}
  end

  def handle_cast({:writeline, message}, state = %{protocol: protocol}) do
    Protocol.writeline(protocol, message)
    {:noreply, state}
  end

  def handle_cast(:quit, state = %{actor_id: actor_id, protocol: protocol}) do
    Logger.info("Player [#{actor_id}] from ip [#{Protocol.ip(protocol)}] quit.")
    Protocol.disconnect(protocol)
    {:stop, :normal, state}
  end

  def handle_info(:welcome_message, state = %{protocol: protocol}) do
    Protocol.write(protocol, "Welcome to the game! What name do you want? ")
    {:noreply, Map.put(state, :state, :get_name)}
  end
end

defimpl Mud.Perceiver, for: Mud.Telnet.Player do
  alias Mud.Telnet.Player
  require Logger

  def can_quit?(_player) do
    true
  end

  def quit(%{pid: pid}) do
    Player.quit(pid)
  end

  def perceive(%{pid: pid}, _actor, Mud.Command.Look, :actor, situation) do
    actors_str =
      situation.room.actors
      |> Enum.filter(fn actor -> actor.id != situation.actor.id end)
      |> Enum.map(fn actor -> "You see #{actor.name} standing here.\r\n" end)

    Player.writeline(
      pid,
      "#{situation.room.name}\r\n#{situation.room.description}\r\n#{actors_str}"
    )
  end

  def perceive(%{pid: pid}, _actor, {Mud.Command.Quit, :success}, role, situation) do
    case role do
      :actor ->
        Player.writeline(pid, "You quit.")

      _ ->
        Player.writeline(pid, "#{situation.actor.name} quits.")
    end
  end

  def perceive(%{pid: pid}, _actor, {Mud.Command.Quit, :failure}, :actor, _situation) do
    Player.writeline(pid, "You must type 'quit' to quit.")
  end

  def perceive(_player, _actor, act, role, _situation) do
    Logger.error("Mud.Player.perceive - unhandled action #{inspect(act)}, role #{inspect(role)}")
  end

  # @spec perceive(pid, term, term, Situation.t()) :: :ok
  # def perceive(pid, act, role, situation) do
  # GenServer.cast(pid, {:perceive, act, role, situation})
  # end
end
