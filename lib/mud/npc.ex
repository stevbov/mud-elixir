defmodule Mud.Npc do
  defstruct blah: nil

  def new() do
    %Mud.Npc{}
  end
end

defimpl Mud.Perceiver, for: Mud.Npc do
  def perceive(_npc, _act, _role, _situation) do
  end
end
