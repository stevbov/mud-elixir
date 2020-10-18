defmodule Mud.CommandDispatcher do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def dispatch(actor_id, module, args) do
    GenServer.call(__MODULE__, {:dispatch, actor_id, module, args})
  end

  def add_actor(actor) do
    GenServer.call(__MODULE__, {:add_actor, actor})
  end

  # GenServer callbacks
  def init(_args) do
    {:ok, world_pid} = Mud.WorldServer.start_link()
    Mud.WorldServer.add_room(world_pid, Mud.Room.new())
    IO.puts("init #{inspect(world_pid)}")
    {:ok, world_pid}
  end

  def handle_call({:dispatch, actor_id, module, args}, _from, world_pid) do
    room_pid = Mud.WorldServer.find_actor_room_pid(world_pid, actor_id)

    case module.scope() do
      :room ->
        Mud.RoomServer.run_async(room_pid, fn room ->
          actor = Mud.Room.find_actor(room, actor_id)
          module.execute(actor, room, args)
        end)

      :world ->
        room_pid = Mud.WorldServer.find_actor_room_pid(world_pid, actor_id)

        actor =
          Mud.RoomServer.run(room_pid, fn room ->
            actor = Mud.Room.find_actor(room, actor_id)
            {:ok, actor, room}
          end)

        module.execute(actor, world_pid, args)
    end

    {:reply, :ok, world_pid}
  end

  def handle_call({:add_actor, actor}, _from, world_pid) do
    IO.puts("add_actor #{inspect(world_pid)}")
    Mud.WorldServer.add_actor(world_pid, actor)
    {:reply, :ok, world_pid}
  end
end
