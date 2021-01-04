defmodule Mud.Actor do
  alias Mud.{Actor, ActorController}

  defstruct id: nil, name: "", inventory: [], controller: nil

  @type id_t :: String.t()

  @type t :: %__MODULE__{id: id_t, name: String.t(), controller: ActorController.t()}

  @spec new(ActorController.t(), id_t | nil) :: t
  def new(controller, id \\ nil) do
    %Actor{
      id: id || UUID.uuid4(),
      name: "a shadowy figure",
      controller: controller
    }
  end
end
