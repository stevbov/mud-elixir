defmodule Mud.Npc do
  defstruct blah: nil

  def new() do
    %Mud.Npc{}
  end
end

defimpl Mud.Perceiver, for: Mud.Npc do
  def can_quit?(_npc) do
    false
  end

  def quit(_npc) do
    raise "Npc cannot quit"
  end

  def perceive(_npc, _actor, _act, _role, _situation) do
  end
end
