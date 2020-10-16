defmodule Mud.Room do
  defstruct id: nil, name: "", description: ""

  def new(id \\ nil) do
    %Mud.Room{
      id: id || UUID.uuid4(),
      name: "An Empty Room",
      description: "You stand in an empty room."
    }
  end
end
