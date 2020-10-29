defmodule Mud.Room do
  alias Mud.{Room, Actor}

  defstruct id: nil, name: "", description: "", actors: []

  @type id_t :: String.t()

  @type t :: %__MODULE__{
          id: id_t | nil,
          name: String.t(),
          description: String.t(),
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
  def add_actor(room, actor) do
    %{room | actors: [actor | room.actors]}
  end

  @spec find_actor(t, Actor.id_t()) :: Actor.t()
  def find_actor(room, actor_id) do
    room.actors |> Enum.find(fn actor -> actor.id == actor_id end)
  end

  @spec remove_actor(t, Actor.id_t()) :: t
  def remove_actor(room, actor_id) do
    updated_actors = Enum.filter(room.actors, fn actor -> actor.id != actor_id end)
    %{room | actors: updated_actors}
  end
end
