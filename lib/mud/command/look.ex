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
    Mud.Action.dispatch(Mud.Command.Look, :actor, %Mud.Situation{actor: actor, room: room})
    {:ok, nil, room}
  end
end
