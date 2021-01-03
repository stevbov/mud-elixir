defmodule Mud.Situation do
  alias Mud.{Actor, Room}

  defstruct actor: nil, target: nil, room: nil

  @type t :: %__MODULE__{actor: Actor.t() | nil, room: Room.t() | nil, target: Actor.t() | nil}
end

defmodule Mud.Action do
  alias Mud.{Actor, Situation}

  @type to :: :actor | :target | :actor_and_target | :room
  @type role :: :actor | :target | :other

  @spec dispatch(term, to, Situation.t()) :: :ok
  def dispatch(act, to, %Situation{} = situation) do
    case to do
      :actor when situation.actor != nil ->
        Mud.Perceiver.perceive(situation.actor.perceiver, situation.actor, act, :actor, situation)

      :target when situation.target != nil ->
        Mud.Perceiver.perceive(
          situation.target.perceiver,
          situation.target,
          act,
          :target,
          situation
        )

      :actor_and_target ->
        dispatch(act, :actor, situation)
        dispatch(act, :target, situation)

      :room ->
        situation.room.actors
        |> Enum.each(fn actor ->
          Mud.Perceiver.perceive(actor.perceiver, actor, act, role(situation, actor), situation)
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
