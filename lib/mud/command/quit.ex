defmodule Mud.Command.Quit do
  alias Mud.RoomServer

  @behaviour Mud.Command

  def parse(cmd, _args, full_input) do
    cond do
      String.starts_with?("quit", cmd) -> %{full_input: full_input}
      true -> nil
    end
  end

  def execute(tx, room_id, actor_id, %{full_input: full_input}) do
    case full_input do
      "quit" ->
        RoomServer.run(room_id, tx, fn room ->
          StmAgent.Transaction.on_verify(tx, fn ->
            actor = Mud.Room.find_actor(room, actor_id)

            Mud.Action.dispatch({__MODULE__, :success}, :room, %Mud.Situation{
              actor: actor,
              room: room
            })
          end)
        end)

        Mud.WorldServer.remove_actor(actor_id, tx)

      _ ->
        RoomServer.run(room_id, tx, fn room ->
          StmAgent.Transaction.on_verify(tx, fn ->
            actor = Mud.Room.find_actor(room, actor_id)
            Mud.Action.dispatch({__MODULE__, :failure}, :actor, %Mud.Situation{actor: actor})
          end)
        end)
    end
  end
end
