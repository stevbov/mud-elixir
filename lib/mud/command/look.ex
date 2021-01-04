defmodule Mud.Command.Look do
  alias Mud.{Npc, Room, Telnet}

  @behaviour Mud.Command

  def parse(cmd, _args, _full_input) do
    if String.starts_with?("look", cmd) do
      %{}
    else
      nil
    end
  end

  def execute(tx, room_id, actor_id, _args) do
    Mud.RoomServer.on_commit(room_id, tx, fn room ->
      actor = Room.find_actor(room, actor_id)
      Mud.Action.dispatch(Mud.Command.Look, nil, :actor, %Mud.Situation{actor: actor, room: room})
    end)
  end

  def perceive(%Telnet.Player{pid: pid}, _args, _actor, :actor, situation) do
    actors_str =
      situation.room.actors
      |> Enum.filter(fn actor -> actor.id != situation.actor.id end)
      |> Enum.map(fn actor -> "You see #{actor.name} standing here.\r\n" end)

    exits_str =
      situation.room.exits
      |> Enum.filter(fn {_direction, exit} -> exit.to_room_id != nil end)
      |> Enum.map(fn {direction, _exit} -> Mud.Direction.to_string(direction) end)
      |> Enum.join(", ")

    Telnet.Player.writeline(
      pid,
      "#{situation.room.name}\r\n#{situation.room.description}\r\nExits: #{exits_str}\r\n#{
        actors_str
      }"
    )
  end

  def perceive(%Npc{}, _args, _actor, _role, _situation) do
  end
end
