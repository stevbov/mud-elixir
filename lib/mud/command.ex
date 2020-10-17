defmodule Mud.Command do
  @type scopes :: :room | :world
  @type args :: map
  @type on_parse :: args | nil

  @callback scope() :: scopes
  @callback parse(String.t()) :: on_parse
  @callback execute(Mud.Actor.t(), term, args) :: term

  @commands [
    Mud.Command.Look,
    Mud.Command.Quit
  ]

  def commands(), do: @commands

  def parse_command(input) do
    commands()
    |> Stream.map(fn module -> {module, module.parse(input)} end)
    |> Stream.filter(fn {_module, args} -> args != nil end)
    |> Enum.fetch(0)
  end
end
