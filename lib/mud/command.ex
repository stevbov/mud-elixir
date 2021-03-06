defmodule Mud.Command do
  alias Mud.WorldServer

  require Logger

  @type args :: map

  @callback parse(String.t(), String.t(), String.t()) :: args | nil
  @callback execute(term, Mud.Room.id_t(), Mud.Actor.id_t(), args) :: Mud.Room.t()
  @callback perceive(
              Mud.ActorController.t(),
              term,
              Mud.Actor.t(),
              Mud.Action.role(),
              Mud.Situation.t()
            ) :: any

  @commands [
    Mud.Command.Move,
    Mud.Command.Look,
    Mud.Command.Quit
  ]

  @spec commands() :: [module]
  def commands(), do: @commands

  @spec execute(Actor.id_t(), String.t()) :: :ok | :invalid
  def execute(actor_id, input) do
    {us, result} =
      :timer.tc(fn ->
        case parse(input) do
          {:ok, {module, args}} ->
            StmAgent.Transaction.transaction(fn tx ->
              room_id = WorldServer.find_actor_room(actor_id, tx)
              module.execute(tx, room_id, actor_id, args)
            end)

            :ok

          _ ->
            :invalid
        end
      end)

    Logger.info("Execute #{inspect(input)} in #{us / 1_000}ms")

    result
  end

  defp parse(input) do
    [cmd | args] = String.split(input, " ", trim: true, parts: 2)

    commands()
    |> Stream.map(fn module -> {module, module.parse(cmd, args, input)} end)
    |> Stream.filter(fn {_module, args} -> args != nil end)
    |> Enum.fetch(0)
  end
end
