defmodule Mud.Command.Quit do
  @behaviour Mud.Command

  def scope(), do: :world

  def parse(cmd, _args, full_input) do
    cond do
      String.starts_with?("quit", cmd) -> %{full_input: full_input}
      true -> nil
    end
  end

  def execute(actor_id, room_pid, world_pid, %{full_input: full_input}) do
    case full_input do
      "quit" ->
        StmAgent.Transaction.transaction(fn tx ->
          Mud.RoomServer.update(
            room_pid,
            fn room ->
              actor = Mud.Room.find_actor(room, actor_id)

              Mud.Action.dispatch({__MODULE__, :success}, :room, %Mud.Situation{
                actor: actor,
                room: room
              })

              Mud.Room.remove_actor(room, actor_id)
            end,
            tx
          )
        end)

        Mud.WorldServer.remove_actor(world_pid, actor_id)
        {:ok}

      _ ->
        actor =
          Mud.RoomServer.dirty_get(room_pid, fn room ->
            Mud.Room.find_actor(room, actor_id)
          end)

        Mud.Action.dispatch({__MODULE__, :failure}, :actor, %Mud.Situation{actor: actor})

        {:ok}
    end
  end
end
