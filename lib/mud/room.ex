defmodule Mud.Room do
  defstruct id: nil, name: "", description: "", actors: []

  @type id_t :: String.t()
  @type t :: %__MODULE__{
          id: id_t,
          name: String.t(),
          description: String.t(),
          actors: [Mud.Actor.t()]
        }

  def new(id \\ nil) do
    %Mud.Room{
      id: id || UUID.uuid4(),
      name: "An Empty Room",
      description: "You stand in an empty room."
    }
  end

  def add_actor(room, actor) do
    %{room | actors: [actor | room.actors]}
  end

  def find_actor(room, actor_id) do
    room.actors |> Enum.find(fn actor -> actor.id == actor_id end)
  end

  def remove_actor(room, actor_id) do
    updated_actors = Enum.filter(room.actors, fn actor -> actor.id != actor_id end)
    %{room | actors: updated_actors}
  end
end
