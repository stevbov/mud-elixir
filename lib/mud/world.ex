defmodule Mud.World do
  alias Mud.World

  defstruct rooms: %{}, default_room_id: nil, actors: %{}

  def new() do
    %World{}
  end

  def add_room(world, room) do
    new_rooms = Map.put(world.rooms, room.id, room)
    new_default_room_id = world.default_room_id || room.id

    %World{
      world
      | rooms: new_rooms,
        default_room_id: new_default_room_id
    }
  end

  def add_actor(world, actor, to_room_id \\ nil) do
    actor = %{actor | room_id: to_room_id || world.default_room_id}
    new_actors = Map.put(world.actors, actor.id, actor)
    %World{world | actors: new_actors}
  end
end
