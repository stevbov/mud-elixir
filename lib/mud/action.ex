defmodule Mud.Action do
  alias Mud.{Actor, Situation}

  @type role :: :actor | :target | :other

  @spec dispatch(term, term, Situation.t()) :: any
  def dispatch(act, to, situation) do
    case to do
      :actor ->
        Mud.Perceiver.perceive(situation.actor.perceiver, act, :actor, situation)

      :target ->
        Mud.Perceiver.perceive(situation.target.perceiver, act, :target, situation)

      :room ->
        situation.room.actors
        |> Enum.each(fn actor ->
          Mud.Perceiver.perceive(actor.perceiver, act, role(situation, actor), situation)
        end)
    end
  end

  @spec role(Situation.t(), Actor.t()) :: role
  def role(situation, actor) do
    cond do
      situation.actor.id == actor.id -> :actor
      situation.target != nil && situation.target.id == actor.id -> :target
      true -> :other
    end
  end
end

defmodule Mud.Situation do
  alias Mud.{Actor, Room}

  defstruct actor: nil, target: nil, room: nil

  @type t :: %__MODULE__{actor: Actor.t() | nil, room: Room.t() | nil, target: Actor.t() | nil}
end
