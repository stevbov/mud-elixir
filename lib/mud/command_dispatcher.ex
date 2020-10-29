defmodule Mud.CommandDispatcher do
  alias Mud.{Actor, Room, RoomServer, WorldServer}
  use GenServer

  @spec start_link(any) :: {:ok, pid}
  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec dispatch(Actor.id_t(), module, term) :: :ok
  def dispatch(actor_id, module, args) do
    GenServer.call(__MODULE__, {:dispatch, actor_id, module, args})
  end

  @spec add_actor(Actor.t()) :: :ok
  def add_actor(actor) do
    GenServer.call(__MODULE__, {:add_actor, actor})
  end

  # GenServer callbacks
  def init(_args) do
    {:ok, world_pid} = WorldServer.start_link()
    WorldServer.add_room(world_pid, Room.new())
    IO.puts("init #{inspect(world_pid)}")
    {:ok, world_pid}
  end

  def handle_call({:dispatch, actor_id, module, args}, _from, world_pid) do
    room_pid = WorldServer.find_actor_room_pid(world_pid, actor_id)

    case module.scope() do
      :room ->
        RoomServer.run_async(room_pid, fn room ->
          actor = Room.find_actor(room, actor_id)
          module.execute(actor, room, args)
        end)

      :world ->
        room_pid = WorldServer.find_actor_room_pid(world_pid, actor_id)
        module.execute(actor_id, room_pid, world_pid, args)
    end

    {:reply, :ok, world_pid}
  end

  def handle_call({:add_actor, actor}, _from, world_pid) do
    IO.puts("add_actor #{inspect(world_pid)}")
    WorldServer.add_actor(world_pid, actor)
    {:reply, :ok, world_pid}
  end
end
