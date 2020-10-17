defmodule Mud.Command.Look do
  @behaviour Mud.Command

  def scope(), do: :room

  def parse(input) do
    [start | _rest] = String.split(input, " ", trim: true, parts: 2)

    if String.starts_with?("look", start) do
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
