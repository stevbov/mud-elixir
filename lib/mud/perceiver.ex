defprotocol Mud.Perceiver do
  alias Mud.{Action, Perceiver, Situation}

  @spec perceive(t, term, Action.role(), Situation.t()) :: any
  def perceive(perceiver, act, role, situation)
end
