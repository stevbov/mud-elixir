defmodule Mud.Telnet.Protocol do
  alias Mud.Telnet.Player
  use GenServer
  require Logger

  @behaviour :ranch_protocol

  def start_link(ref, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, transport])
    {:ok, pid}
  end

  def write(protocol, str) do
    GenServer.cast(protocol, {:send, str})
  end

  # GenServer callbacks
  def init(ref, transport) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, [{:active, true}])
    {:ok, {ip, _port}} = :inet.peername(socket)
    ip = :inet.ntoa(ip)
    {:ok, player} = Player.start_link(self())
    Logger.info("Socket Connect - ip [#{ip}]")
    :gen_server.enter_loop(__MODULE__, [], %{ip: ip, player: player, transport: transport, socket: socket})
  end

  def handle_cast({:send, str}, state = %{transport: transport, socket: socket}) do
    transport.send(socket, str)
    {:noreply, state}
  end

  def handle_info({:tcp, socket, data}, state = %{player: player}) do
    Player.handle_input(player, data)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, state = %{ip: ip, transport: transport}) do
    Logger.info("Socket Disconnect - ip [#{ip}]")
    transport.close(socket)
    {:stop, :normal, state}
  end

end
