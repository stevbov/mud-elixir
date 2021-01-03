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
    RoomServer.run(room_id, tx, fn _room ->
      # TODO: fix dirty hack - this is so the transaction has a reference to the room
      :ok
    end)

    can_quit =
      RoomServer.get(room_id, tx, fn room ->
        actor = Mud.Room.find_actor(room, actor_id)
        Mud.Perceiver.can_quit?(actor.perceiver)
      end)

    if can_quit do
      case full_input do
        "quit" ->
          RoomServer.on_commit(room_id, tx, fn room ->
            actor = Mud.Room.find_actor(room, actor_id)

            Mud.Action.dispatch({__MODULE__, :success}, :room, %Mud.Situation{
              actor: actor,
              room: room
            })

            Mud.Perceiver.quit(actor.perceiver)
          end)

          Mud.WorldServer.remove_actor(actor_id, tx)

        _ ->
          RoomServer.on_commit(room_id, tx, fn room ->
            actor = Mud.Room.find_actor(room, actor_id)

            Mud.Action.dispatch({__MODULE__, :failure}, :actor, %Mud.Situation{
              actor: actor,
              room: room
            })
          end)
      end
    else
      RoomServer.on_commit(room_id, tx, fn room ->
        actor = Mud.Room.find_actor(room, actor_id)

        Mud.Action.dispatch({__MODULE__, :cannot}, :actor, %Mud.Situation{
          actor: actor,
          room: room
        })
      end)
    end
  end
end
