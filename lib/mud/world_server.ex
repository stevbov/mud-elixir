defmodule Mud.WorldServer do
  use StmAgent

  alias Mud.{Actor, Room}

  require Logger

  defstruct room_ids: nil, actor_rooms: %{}, default_room_id: nil

  @spec start_link(term) :: {:ok, pid}
  def start_link(_opts) do
    Logger.info("World starting")

    result =
      StmAgent.start_link(fn -> %Mud.WorldServer{room_ids: MapSet.new()} end, name: __MODULE__)

    StmAgent.Transaction.transaction(fn tx ->
      Mud.WorldServer.add_room(Room.new(), tx)
    end)

    result
  end

  @spec find_actor_room(Actor.id_t(), term) :: Room.id_t() | nil
  def find_actor_room(actor_id, tx) do
    StmAgent.get!(__MODULE__, tx, fn state ->
      Map.get(state.actor_rooms, actor_id)
    end)
  end

  @spec add_room(Room.t(), term) :: :ok
  def add_room(%Room{} = room, tx) do
    {:ok, _} = Mud.RoomServer.start_link(room)

    StmAgent.Transaction.on_abort(tx, fn ->
      Mud.RoomServer.stop(room.id)
    end)

    StmAgent.update!(__MODULE__, tx, fn state ->
      updated_room_ids = MapSet.put(state.room_ids, room.id)

      updated_actor_rooms =
        room.actors
        |> Enum.reduce(state.actor_rooms, fn actor, sofar ->
          Map.put(sofar, room.id, actor.id)
        end)

      updated_default_room_id = state.default_room_id || room.id

      %{
        state
        | room_ids: updated_room_ids,
          default_room_id: updated_default_room_id,
          actor_rooms: updated_actor_rooms
      }
    end)
  end

  @spec add_actor(Actor.t(), Room.id_t() | nil) :: Room.id_t()
  def add_actor(%Actor{} = actor, to_room_id \\ nil) do
    StmAgent.Transaction.transaction(fn tx ->
      StmAgent.update!(__MODULE__, tx, fn state ->
        to_room_id = to_room_id || state.default_room_id

        updated_actor_rooms = Map.put(state.actor_rooms, actor.id, to_room_id)
        Mud.RoomServer.update(to_room_id, tx, fn room -> Mud.Room.add_actor(room, actor) end)

        %{state | actor_rooms: updated_actor_rooms}
      end)
    end)
  end

  @spec remove_actor(Actor.id_t(), term) :: :ok
  def remove_actor(actor_id, tx) do
    StmAgent.update!(__MODULE__, tx, fn state ->
      room_id = state.actor_rooms[actor_id]

      {_, updated_actor_rooms} = Map.pop!(state.actor_rooms, actor_id)

      Mud.RoomServer.update(room_id, tx, fn room ->
        Mud.Room.remove_actor(room, actor_id)
      end)

      %{state | actor_rooms: updated_actor_rooms}
    end)
  end
end
