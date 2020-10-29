defmodule Mud.Actor do
  alias Mud.{Actor, Perceiver}

  defstruct id: nil, name: "", perceiver: nil

  @type id_t :: String.t()

  @type t :: %__MODULE__{id: id_t, name: String.t(), perceiver: Perceiver.t()}

  @spec new(Perceiver.t(), id_t | nil) :: t
  def new(perceiver, id \\ nil) do
    %Actor{
      id: id || UUID.uuid4(),
      name: "a shadowy figure",
      perceiver: perceiver
    }
  end
end
