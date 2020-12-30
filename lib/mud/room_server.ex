defmodule Mud.RoomServer do
  alias Mud.Room

  @spec start_link(Room.t()) :: {:ok, pid}
  def start_link(room) do
    StmAgent.start_link(fn -> room end, name: via_tuple(room.id))
  end

  @spec stop(Room.id_t()) :: term
  def stop(id) do
    StmAgent.stop(via_tuple(id))
  end

  @spec run(Room.id_t(), fun, term) :: term
  def run(id, fun, tx) do
    StmAgent.get!(
      via_tuple(id),
      fn room ->
        fun.(room)
        :ok
      end,
      tx
    )
  end

  @spec get(Room.id_t(), fun, term) :: term
  def get(id, fun, tx) do
    StmAgent.get!(via_tuple(id), fun, tx)
  end

  @spec update(Room.id_t(), fun, term) :: term
  def update(id, fun, tx) do
    StmAgent.update!(via_tuple(id), fun, tx)
  end

  @spec get_and_update(Room.id_t(), fun, term) :: term
  def get_and_update(id, fun, tx) do
    StmAgent.get_and_update!(via_tuple(id), fun, tx)
  end

  @spec cast(Room.id_t(), fun, term) :: term
  def cast(id, fun, tx) do
    StmAgent.cast(via_tuple(id), fun, tx)
  end

  @spec dirty_get(Room.id_t(), fun) :: term
  def dirty_get(id, fun) do
    StmAgent.dirty_get(via_tuple(id), fun)
  end

  @spec dirty_update(Room.id_t(), fun) :: term
  def dirty_update(id, fun) do
    StmAgent.dirty_update(via_tuple(id), fun)
  end

  @spec dirty_get_and_update(Room.id_t(), fun) :: term
  def dirty_get_and_update(id, fun) do
    StmAgent.dirty_get_and_update(via_tuple(id), fun)
  end

  defp via_tuple(id) do
    {:via, Registry, {Mud.RoomServer.Registry, id}}
  end
end
