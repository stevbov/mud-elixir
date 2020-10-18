defmodule Mud.Command.Quit do
  @behaviour Mud.Command

  def scope(), do: :world

  def parse(cmd, _args, full_input) do
    cond do
      String.starts_with?("quit", cmd) -> %{full_input: full_input}
      true -> nil
    end
  end

  def execute(actor, world_pid, %{full_input: full_input}) do
    case full_input do
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
