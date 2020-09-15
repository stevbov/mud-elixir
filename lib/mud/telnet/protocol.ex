defmodule Mud.Telnet.Protocol do
  use GenServer
  require Logger

  @behaviour :ranch_protocol

  def start_link(ref, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, transport])
    {:ok, pid}
  end

  def init(ref, transport) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, [{:active, true}])
    {:ok, {ip, _port}} = :inet.peername(socket)
    ip = :inet.ntoa(ip)
    Logger.info("Socket Connect - ip [#{ip}]")
    :gen_server.enter_loop(__MODULE__, [], %{ip: ip, transport: transport})
  end

  def handle_info({:tcp, socket, data}, state = %{transport: transport}) do
    transport.send(socket, data)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, state = %{ip: ip, transport: transport}) do
    Logger.info("Socket Disconnect - ip [#{ip}]")
    transport.close(socket)
    {:stop, :normal, state}
  end
end
