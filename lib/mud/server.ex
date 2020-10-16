defmodule Mud.Server do
  alias Mud.{Perceiver, Room, World}

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

  def add_actor(actor, perceiver) do
    GenServer.cast(__MODULE__, {:add_actor, actor, perceiver})
  end

  def handle_input(actor_id, input) do
    GenServer.cast(__MODULE__, {:input, actor_id, input})
  end

  # GenServer callbacks
  def init(_args) do
    world =
      World.new()
      |> World.add_room(Room.new())

    {:ok, %{world: world, perceivers: %{}}}
  end

  def handle_cast({:add_actor, actor, perceiver}, state = %{world: world, perceivers: perceivers}) do
    new_world = World.add_actor(world, actor)
    new_perceivers = Map.put(perceivers, actor.id, perceiver)
    {:noreply, %{state | world: new_world, perceivers: new_perceivers}}
  end

  def handle_cast({:input, actor_id, "look"}, state = %{world: world, perceivers: perceivers}) do
    actor = Map.get(world.actors, actor_id)
    room = Map.get(world.rooms, actor.room_id)
    perceiver = Map.get(perceivers, actor_id)

    Perceiver.perceive(perceiver, "#{room.name}\r\n#{room.description}\r\n")
    {:noreply, state}
  end

  def handle_cast({:input, actor_id, input}, state = %{perceivers: perceivers}) do
    perceiver = Map.get(perceivers, actor_id)

    Perceiver.perceive(perceiver, "Huh!?\r\n")
    {:noreply, state}
  end
end
