defmodule Mud.RoomServer do
  alias Mud.Room

  use GenServer

  @type fun :: (Room.t() -> {:ok, term, Room.t()})

  @spec start_link(Room.t()) :: {:ok, pid}
  def start_link(room) do
    GenServer.start_link(__MODULE__, room)
  end

  @spec run(pid, fun) :: term
  def run(pid, fun) do
    GenServer.call(pid, {:run, fun})
  end

  @spec run_async(pid, fun) :: :ok
  def run_async(pid, fun) do
    GenServer.cast(pid, {:run, fun})
  end

  # GenServer callbacks
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
