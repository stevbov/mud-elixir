defmodule Mud.Command.Quit do
  alias Mud.{Npc, RoomServer, Telnet}

  @behaviour Mud.Command

  def parse(cmd, _args, full_input) do
    cond do
      String.starts_with?("quit", cmd) -> %{full_input: full_input}
      true -> nil
    end
  end

  def execute(tx, room_id, actor_id, %{full_input: full_input}) do
    can_quit =
      RoomServer.get(room_id, tx, fn room ->
        actor = Mud.Room.find_actor(room, actor_id)
        Mud.ActorController.can_quit?(actor.controller)
      end)

    if can_quit do
      case full_input do
        "quit" ->
          actor =
            RoomServer.get(room_id, tx, fn room ->
              Mud.Room.find_actor(room, actor_id)
            end)

          RoomServer.on_commit(room_id, tx, fn room ->
            Mud.Action.dispatch(__MODULE__, :success, :room_not_actor, %Mud.Situation{
              actor: actor,
              room: room
            })

            Mud.Action.dispatch(__MODULE__, :success, :actor, %Mud.Situation{
              actor: actor,
              room: room
            })

            Mud.ActorController.quit(actor.controller)
          end)

          Mud.WorldServer.remove_actor(actor_id, tx)

        _ ->
          RoomServer.on_commit(room_id, tx, fn room ->
            actor = Mud.Room.find_actor(room, actor_id)

            Mud.Action.dispatch(__MODULE__, :failure, :actor, %Mud.Situation{
              actor: actor,
              room: room
            })
          end)
      end
    else
      RoomServer.on_commit(room_id, tx, fn room ->
        actor = Mud.Room.find_actor(room, actor_id)

        Mud.Action.dispatch(__MODULE__, :cannot, :actor, %Mud.Situation{
          actor: actor,
          room: room
        })
      end)
    end
  end

  def perceive(%Telnet.Player{pid: pid}, :success, _actor, role, situation) do
    case role do
      :actor ->
        Telnet.Player.writeline(pid, "You quit.")

      _ ->
        Telnet.Player.writeline(pid, "#{situation.actor.name} quits.")
    end
  end

  def perceive(%Telnet.Player{pid: pid}, :failure, _actor, :actor, _situation) do
    Telnet.Player.writeline(pid, "You must type 'quit' to quit.")
  end

  def perceive(%Npc{}, _args, _actor, _role, _situation) do
  end
end
