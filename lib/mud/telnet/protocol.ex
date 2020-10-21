defmodule Mud.Telnet.Protocol do
  alias Mud.Telnet.Player
  use GenServer
  require Logger

  @behaviour :ranch_protocol

  def start_link(ref, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, transport])
    {:ok, pid}
  end

  def ip(protocol) do
    GenServer.call(protocol, :ip)
  end

  def write(protocol, str) do
    GenServer.cast(protocol, {:send, str})
  end

  def writeline(protocol, str) do
    GenServer.cast(protocol, {:send, "#{str}\r\n"})
  end

  def disconnect(protocol) do
    GenServer.cast(protocol, :disconnect)
  end

  # GenServer callbacks
  def init(ref, transport) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, [{:active, true}])
    {:ok, {ip, _port}} = :inet.peername(socket)
    ip = :inet.ntoa(ip)
    {:ok, player} = Player.start_link(self())
    Logger.info("Socket Connect - ip [#{ip}]")

    :gen_server.enter_loop(__MODULE__, [], %{
      ip: ip,
      player: player,
      transport: transport,
      socket: socket
    })
  end

  def handle_call(:ip, _from, state = %{ip: ip}) do
    {:reply, ip, state}
  end

  def handle_cast({:send, str}, state = %{transport: transport, socket: socket}) do
    transport.send(socket, str)
    {:noreply, state}
  end

  def handle_cast(:disconnect, state = %{transport: transport, socket: socket}) do
    transport.close(socket)
    {:stop, :normal, state}
  end

  def handle_info({:tcp, socket, data}, state = %{player: player}) do
    Player.handle_input(player, String.trim(data))
    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, state = %{ip: ip, transport: transport}) do
    Logger.info("Socket disconnected - ip [#{ip}]")
    transport.close(socket)
    {:stop, :normal, state}
  end
end
