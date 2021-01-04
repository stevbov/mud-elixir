defmodule Mud.Room do
  alias Mud.{Direction, Exit, Room, Actor}

  defstruct id: nil, name: "", description: "", exits: %{}, actors: []

  @type id_t :: String.t()

  @type t :: %__MODULE__{
          id: id_t | nil,
          name: String.t(),
          description: String.t(),
          exits: %{},
          actors: [Mud.Actor.t()]
        }

  @spec new(id_t | nil) :: t
  def new(id \\ nil) do
    %Room{
      id: id || UUID.uuid4(),
      name: "An Empty Room",
      description: "You stand in an empty room."
    }
  end

  @spec add_actor(t, Actor.t()) :: t
  def add_actor(%Room{} = room, %Actor{} = actor) do
    %{room | actors: [actor | room.actors]}
  end

  @spec find_actor(t, Actor.id_t()) :: Actor.t()
  def find_actor(%Room{} = room, actor_id) do
    room.actors |> Enum.find(fn actor -> actor.id == actor_id end)
  end

  @spec remove_actor(t, Actor.id_t()) :: t
  def remove_actor(%Room{} = room, actor_id) do
    updated_actors = Enum.filter(room.actors, fn actor -> actor.id != actor_id end)
    %{room | actors: updated_actors}
  end

  @spec link(Room.t(), Room.t(), Direction.t()) :: {Room.t(), Room.t()}
  def link(%Room{} = room1, %Room{} = room2, direction) do
    exit1 = Exit.new() |> Map.put(:to_room_id, room2.id)
    exit2 = Exit.new() |> Map.put(:to_room_id, room1.id)

    new_room1 = %{room1 | exits: Map.put(room1.exits, direction, exit1)}
    new_room2 = %{room2 | exits: Map.put(room2.exits, Direction.reverse(direction), exit2)}

    {new_room1, new_room2}
  end
end
