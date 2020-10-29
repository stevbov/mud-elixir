defmodule Mud.Command do
  @type scopes :: :room | :world
  @type args :: map

  @callback scope() :: scopes
  @callback parse(String.t(), String.t(), String.t()) :: args | nil
  # this doesn't really fit anymore... probably need to come up with a better design
  # @callback execute(Mud.Actor.t(), term, args) :: term

  @commands [
    Mud.Command.Look,
    Mud.Command.Quit
  ]

  @spec commands() :: [module]
  def commands(), do: @commands

  @spec parse_command(String.t()) :: {:ok, {module, args}} | :error
  def parse_command(input) do
    [cmd | args] = String.split(input, " ", trim: true, parts: 2)

    commands()
    |> Stream.map(fn module -> {module, module.parse(cmd, args, input)} end)
    |> Stream.filter(fn {_module, args} -> args != nil end)
    |> Enum.fetch(0)
  end
end
