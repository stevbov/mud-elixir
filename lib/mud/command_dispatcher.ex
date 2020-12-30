defmodule Mud.CommandDispatcher do
  alias Mud.{Actor, WorldServer}

  @spec dispatch(Actor.id_t(), module, term) :: :ok
  def dispatch(actor_id, module, args) do
    StmAgent.Transaction.transaction(fn tx ->
      room_id = WorldServer.find_actor_room(actor_id, tx)
      module.execute(tx, room_id, actor_id, args)
    end)
  end
end
