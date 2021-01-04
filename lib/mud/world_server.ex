defmodule Mud.WorldServer do
  use StmAgent

  alias Mud.{Actor, Room, RoomServer}

  require Logger

  defstruct room_ids: nil, actor_rooms: %{}, actor_actors: %{}, default_room_id: nil

  @spec start_link(term) :: {:ok, pid}
  def start_link(_opts) do
    Logger.info("World starting")

    result =
      StmAgent.start_link(fn -> %Mud.WorldServer{room_ids: MapSet.new()} end, name: __MODULE__)

    room1 = Room.new()
    room2 = Room.new()
    {room1, room2} = Room.link(room1, room2, :north)

    StmAgent.Transaction.transaction(fn tx ->
      Mud.WorldServer.add_room(room1, tx)
      Mud.WorldServer.add_room(room2, tx)
    end)

    Mud.WorldServer.add_actor(Actor.new(Mud.Npc.new()) |> Map.put(:name, "a sword"))
    Mud.WorldServer.add_actor(Actor.new(Mud.Npc.new()) |> Map.put(:name, "a shield"))
    Mud.WorldServer.add_actor(Actor.new(Mud.Npc.new()) |> Map.put(:name, "a shirt of chain mail"))

    Mud.WorldServer.add_actor(
      Actor.new(Mud.Npc.new())
      |> Map.put(:name, "a hard leather cuirass")
    )

    Mud.WorldServer.add_actor(Actor.new(Mud.Npc.new()) |> Map.put(:name, "a bronze cuirass"))

    for _n <- 1..20 do
      chest_inventory =
        for _n <- 1..3000, do: Actor.new(Mud.Npc.new()) |> Map.put(:name, "a loaf of bread")

      Actor.new(Mud.Npc.new())
      |> Map.put(:name, "a wooden chest")
      |> Map.put(:inventory, chest_inventory)
    end
    |> Enum.each(&Mud.WorldServer.add_actor/1)

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

        updated_actor_actors =
          Enum.reduce(actor.inventory, state.actor_actors, fn a, acc ->
            Map.put(acc, a.id, actor.id)
          end)

        Mud.RoomServer.update(to_room_id, tx, fn room -> Mud.Room.add_actor(room, actor) end)

        %{state | actor_rooms: updated_actor_rooms, actor_actors: updated_actor_actors}
      end)
    end)
  end

  @spec move_actor(Actor.id_t(), Room.id_t(), term) :: any
  def move_actor(actor_id, to_room_id, tx) do
    old_room_id =
      StmAgent.get_and_update!(__MODULE__, tx, fn state ->
        old_room_id = Map.get(state.actor_rooms, actor_id)
        updated_actor_rooms = Map.put(state.actor_rooms, actor_id, to_room_id)
        {old_room_id, %{state | actor_rooms: updated_actor_rooms}}
      end)

    actor =
      RoomServer.get_and_update(old_room_id, tx, fn room ->
        actor = Room.find_actor(room, actor_id)
        new_room = Room.remove_actor(room, actor_id)
        {actor, new_room}
      end)

    RoomServer.update(to_room_id, tx, fn room ->
      Room.add_actor(room, actor)
    end)

    actor
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
