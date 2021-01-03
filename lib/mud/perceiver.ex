defprotocol Mud.Perceiver do
  alias Mud.{Action, Actor, Situation}

  @spec can_quit?(t) :: bool
  def can_quit?(perceiver)

  @spec quit(t) :: any
  def quit(perceiver)

  @spec perceive(t, Actor.t(), term, Action.role(), Situation.t()) :: any
  def perceive(perceiver, actor, act, role, situation)
end
