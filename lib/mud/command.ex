defmodule Mud.Command do
  @type scopes :: :room | :world
  @type args :: map
  @type on_parse :: args | nil

  @callback scope() :: scopes
  @callback parse(String.t(), String.t(), String.t()) :: on_parse
  @callback execute(Mud.Actor.t(), term, args) :: term

  @commands [
    Mud.Command.Look,
    Mud.Command.Quit
  ]

  def commands(), do: @commands

  def parse_command(input) do
    [cmd | args] = String.split(input, " ", trim: true, parts: 2)
    commands()
    |> Stream.map(fn module -> {module, module.parse(cmd, args, input)} end)
    |> Stream.filter(fn {_module, args} -> args != nil end)
    |> Enum.fetch(0)
  end
end
