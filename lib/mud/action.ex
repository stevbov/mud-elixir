defmodule Mud.Situation do
  alias Mud.{Actor, Room}

  defstruct actor: nil, target: nil, room: nil

  @type t :: %__MODULE__{actor: Actor.t() | nil, room: Room.t() | nil, target: Actor.t() | nil}
end

defmodule Mud.Action do
  alias Mud.{Actor, Situation}

  @type to :: :actor | :target | :actor_and_target | :room | :room_not_actor
  @type role :: :actor | :target | :other

  @spec dispatch(module, term, to, Situation.t()) :: :ok
  def dispatch(cmd_module, args, to, %Situation{} = situation) do
    case to do
      :actor when situation.actor != nil ->
        cmd_module.perceive(situation.actor.controller, args, situation.actor, :actor, situation)

      :target when situation.target != nil ->
        cmd_module.perceive(
          situation.target.controller,
          args,
          situation.target,
          :target,
          situation
        )

      :actor_and_target ->
        dispatch(cmd_module, args, :actor, situation)
        dispatch(cmd_module, args, :target, situation)

      :room ->
        situation.room.actors
        |> Enum.each(fn actor ->
          cmd_module.perceive(actor.controller, args, actor, role(situation, actor), situation)
        end)

      :room_not_actor ->
        situation.room.actors
        |> Enum.filter(fn actor -> role(situation, actor) != :actor end)
        |> Enum.each(fn actor ->
          cmd_module.perceive(actor.controller, args, actor, role(situation, actor), situation)
        end)
    end

    :ok
  end

  @spec role(Situation.t(), Actor.t()) :: role
  def role(%Situation{} = situation, %Actor{} = actor) do
    cond do
      situation.actor != nil && situation.actor.id == actor.id -> :actor
      situation.target != nil && situation.target.id == actor.id -> :target
      true -> :other
    end
  end
end
