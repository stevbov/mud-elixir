defprotocol Mud.ActorController do
  @spec can_quit?(t) :: bool
  def can_quit?(controller)

  @spec quit(t) :: any
  def quit(controller)
end
