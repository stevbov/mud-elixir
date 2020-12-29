defmodule Mud.WorldServer do
  alias Mud.{Actor, Room}

  use GenServer

  require Logger

  defstruct room_pids: %{}, actor_rooms: %{}, default_room_id: nil

  @spec start_link() :: {:ok, pid}
  def start_link() do
    Logger.info("World starting")
    GenServer.start_link(__MODULE__, nil)
  end

  @spec find_actor_room(pid, Actor.id_t()) :: Room.t() | nil
  def find_actor_room(pid, actor_id) do
    GenServer.call(pid, {:find_actor_room, actor_id})
  end

  @spec find_actor_room_pid(pid, Actor.id_t()) :: pid | nil
  def find_actor_room_pid(pid, actor_id) do
    GenServer.call(pid, {:find_actor_room_pid, actor_id})
  end

  @spec add_room(pid, Room.t()) :: :ok
  def add_room(pid, %Room{} = room) do
    GenServer.call(pid, {:add_room, room})
  end

  @spec add_actor(pid, Actor.t(), Room.id_t() | nil) :: Room.id_t()
  def add_actor(pid, %Actor{} = actor, to_room_id \\ nil) do
    GenServer.call(pid, {:add_actor, actor, to_room_id})
  end

  @spec remove_actor(pid, Actor.id_t()) :: :ok
  def remove_actor(pid, actor_id) do
    GenServer.call(pid, {:remove_actor, actor_id})
  end

  # GenServer callbacks
  def init(_args) do
    {:ok, %Mud.WorldServer{}}
  end

  def handle_call({:find_actor_room, actor_id}, _from, state) do
    {:reply, Map.get(state.actor_rooms, actor_id), state}
  end

  def handle_call({:find_actor_room_pid, actor_id}, _from, state) do
    room_id = state.actor_rooms[actor_id]
    room_pid = state.room_pids[room_id]
    {:reply, room_pid, state}
  end

  def handle_call({:add_room, room}, _from, state) do
    {:ok, room_pid} = Mud.RoomServer.start_link(room)
    updated_room_pids = Map.put(state.room_pids, room.id, room_pid)

    updated_actor_rooms =
      room.actors
      |> Enum.reduce(state.actor_rooms, fn actor, sofar -> Map.put(sofar, room.id, actor.id) end)

    updated_default_room_id = state.default_room_id || room.id

    updated_state = %{
      state
      | room_pids: updated_room_pids,
        default_room_id: updated_default_room_id,
        actor_rooms: updated_actor_rooms
    }

    {:reply, :ok, updated_state}
  end

  def handle_call({:add_actor, actor, to_room_id}, _from, state) do
    to_room_id = to_room_id || state.default_room_id
    room_pid = state.room_pids[to_room_id]

    updated_actor_rooms = Map.put(state.actor_rooms, actor.id, to_room_id)

    Mud.RoomServer.dirty_update(room_pid, fn room ->
      Mud.Room.add_actor(room, actor)
    end)

    updated_state = %{state | actor_rooms: updated_actor_rooms}
    {:reply, to_room_id, updated_state}
  end

  def handle_call({:remove_actor, actor_id}, _from, state) do
    room_id = state.actor_rooms[actor_id]
    room_pid = state.room_pids[room_id]

    {_, updated_actor_rooms} = Map.pop!(state.actor_rooms, actor_id)

    Mud.RoomServer.dirty_update(room_pid, fn room ->
      Mud.Room.remove_actor(room, actor_id)
    end)

    updated_state = %{state | actor_rooms: updated_actor_rooms}
    {:reply, :ok, updated_state}
  end
end
