defmodule Mud.RoomServer do
  use GenServer

  def start_link(room) do
    GenServer.start_link(__MODULE__, room)
  end

  def run(pid, fun) do
    GenServer.call(pid, {:run, fun})
  end

  def run_async(pid, fun) do
    GenServer.cast(pid, {:run, fun})
  end

  def init(room) do
    {:ok, room}
  end

  def handle_call({:run, fun}, _from, room) do
    {:ok, reply, new_room} = fun.(room)
    {:reply, reply, new_room}
  end

  def handle_cast({:run, fun}, room) do
    {:ok, _reply, new_room} = fun.(room)
    {:noreply, new_room}
  end
end
