defmodule Mud.RoomServer do
  alias Mud.Room

  @spec start_link(Room.t()) :: {:ok, pid}
  def start_link(room) do
    StmAgent.start_link(fn -> room end)
  end

  @spec get(pid, fun, term) :: term
  def get(pid, fun, tx) do
    StmAgent.get!(pid, fun, tx)
  end

  @spec update(pid, fun, term) :: term
  def update(pid, fun, tx) do
    StmAgent.update!(pid, fun, tx)
  end

  @spec get_and_update(pid, fun, term) :: term
  def get_and_update(pid, fun, tx) do
    StmAgent.get_and_update!(pid, fun, tx)
  end

  @spec cast(pid, fun, term) :: term
  def cast(pid, fun, tx) do
    StmAgent.cast!(pid, fun, tx)
  end

  @spec dirty_get(pid, fun) :: term
  def dirty_get(pid, fun) do
    StmAgent.dirty_get(pid, fun)
  end

  @spec dirty_update(pid, fun) :: term
  def dirty_update(pid, fun) do
    StmAgent.dirty_update(pid, fun)
  end

  @spec dirty_get_and_update(pid, fun) :: term
  def dirty_get_and_update(pid, fun) do
    StmAgent.dirty_get_and_update(pid, fun)
  end
end
