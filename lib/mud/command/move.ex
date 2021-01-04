defmodule Mud.Command.Move do
  alias Mud.{Direction, RoomServer}

  @behaviour Mud.Command

  def parse(cmd, _args, _full_input) do
    case Direction.directions()
         |> Enum.filter(&String.starts_with?(to_string(&1), cmd))
         |> Enum.fetch(0) do
      {:ok, direction} -> direction
      :error -> nil
    end
  end

  def execute(tx, room_id, actor_id, direction) do
    # find the exit
    result =
      RoomServer.get(room_id, tx, fn room ->
        case Map.fetch(room.exits, direction) do
          {:ok, exit} when exit.to_room_id != nil ->
            {:ok, exit}

          _ ->
            :error
        end
      end)

    # process the movement
    case result do
      {:ok, exit} ->
        actor = Mud.WorldServer.move_actor(actor_id, exit.to_room_id, tx)

        RoomServer.on_commit(room_id, tx, fn room ->
          Mud.Action.dispatch({__MODULE__, :leave, direction}, :room, %Mud.Situation{
            actor: actor,
            room: room
          })
        end)

        RoomServer.on_commit(exit.to_room_id, tx, fn room ->
          Mud.Action.dispatch(
            {__MODULE__, :enter, Mud.Direction.reverse(direction)},
            :room,
            %Mud.Situation{
              actor: actor,
              room: room
            }
          )
        end)

      :error ->
        RoomServer.on_commit(room_id, tx, fn room ->
          actor = Mud.Room.find_actor(room, actor_id)

          Mud.Action.dispatch({__MODULE__, :no_exit, direction}, :actor, %Mud.Situation{
            actor: actor,
            room: room
          })
        end)
    end
  end
end
