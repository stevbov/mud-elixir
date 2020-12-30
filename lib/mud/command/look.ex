defmodule Mud.Command.Look do
  alias Mud.Room

  @behaviour Mud.Command

  def scope(), do: :room

  def parse(cmd, _args, _full_input) do
    if String.starts_with?("look", cmd) do
      %{}
    else
      nil
    end
  end

  def execute(tx, room_id, actor_id, _args) do
    Mud.RoomServer.run(
      room_id,
      fn room ->
        StmAgent.Transaction.on_verify(tx, fn ->
          actor = Room.find_actor(room, actor_id)
          Mud.Action.dispatch(Mud.Command.Look, :actor, %Mud.Situation{actor: actor, room: room})
        end)
      end,
      tx
    )
  end
end
