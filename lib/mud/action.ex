defmodule Mud.Action do
  def dispatch(act, to, situation) do
    case to do
      :actor ->
        Mud.Perceiver.perceive(situation.actor.perceiver, act, :actor, situation)
      :target ->
        Mud.Perceiver.perceive(situation.target.perceiver, act, :target, situation)
      :room ->
        situation.room.actors
        |> Enum.each(fn actor -> Mud.Perceiver.perceive(actor.perceiver, act, role(situation, actor), situation) end)
    end
  end

  def role(situation, actor) do
    cond do
      situation.actor.id == actor.id -> :actor
      situation.target != nil && situation.target.id == actor.id -> :target
      true -> :other
    end
  end
end

defmodule Mud.Situation do
  @type t :: %__MODULE__{actor: Mud.Actor.t(), room: Mud.Room.t(), target: Mud.Actor.t()}
  defstruct actor: nil, target: nil, room: nil
end