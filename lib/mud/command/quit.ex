defmodule Mud.Command.Quit do
  @behaviour Mud.Command

  def scope(), do: :world

  def parse(input) do
    [start | _rest] = String.split(input, " ", trim: true, parts: 2)

    cond do
      String.starts_with?("quit", start) -> %{input: start}
      true -> nil
    end
  end

  def execute(actor, world_pid, %{input: start}) do
    case start do
      "quit" ->
        Mud.WorldServer.remove_actor(world_pid, actor.id)
        Mud.Perceiver.perceive(actor.perceiver, {__MODULE__, :success})
        {:ok}

      _ ->
        Mud.Perceiver.perceive(actor.perceiver, {__MODULE__, :failure})
        {:ok}
    end
  end
end
