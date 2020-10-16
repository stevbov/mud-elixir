defmodule Mud.Server do
  alias Mud.{Perceptor, Room, World}

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

  def add_actor(actor, perceptor) do
    GenServer.cast(__MODULE__, {:add_actor, actor, perceptor})
  end

  def handle_input(actor_id, input) do
    GenServer.cast(__MODULE__, {:input, actor_id, input})
  end

  # GenServer callbacks
  def init(_args) do
    world =
      World.new()
      |> World.add_room(Room.new())

    {:ok, %{world: world, perceptors: %{}}}
  end

  def handle_cast({:add_actor, actor, perceptor}, state = %{world: world, perceptors: perceptors}) do
    new_world = World.add_actor(world, actor)
    new_perceptors = Map.put(perceptors, actor.id, perceptor)
    {:noreply, %{state | world: new_world, perceptors: new_perceptors}}
  end

  def handle_cast({:input, actor_id, "look"}, state = %{world: world, perceptors: perceptors}) do
    actor = Map.get(world.actors, actor_id)
    room = Map.get(world.rooms, actor.room_id)
    perceptor = Map.get(perceptors, actor_id)

    Perceptor.perceive(perceptor, "#{room.name}\r\n#{room.description}\r\n")
    {:noreply, state}
  end

  def handle_cast({:input, actor_id, input}, state = %{perceptors: perceptors}) do
    perceptor = Map.get(perceptors, actor_id)

    Perceptor.perceive(perceptor, "Huh!?\r\n")
    {:noreply, state}
  end
end
