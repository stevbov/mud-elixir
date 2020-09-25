defmodule Mud.Game.Actor do
  alias Mud.Game.Actor

  defstruct id: nil, name: "", room_id: nil

  def new(id \\ nil) do
    %Actor{
      id: id || UUID.uuid4(),
      name: "a shadowy figure"
    }
  end
end