defmodule Mud.Exit do
  defstruct to_room_id: nil, description: nil

  @type t :: %__MODULE__{
          to_room_id: Mud.Room.t() | nil,
          description: String.t() | nil
        }

  def new() do
    %Mud.Exit{}
  end
end
