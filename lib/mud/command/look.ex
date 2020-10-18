defmodule Mud.Command.Look do
  @behaviour Mud.Command

  def scope(), do: :room

  def parse(cmd, _args, _full_input) do
    if String.starts_with?("look", cmd) do
      %{}
    else
      nil
    end
  end

  def execute(actor, room, _args) do
    Mud.Perceiver.perceive(actor.perceiver, {__MODULE__, room})
    {:ok, nil, room}
  end
end
