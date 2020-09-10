defmodule Telnet.Listener do
  require Logger

  def start_link(port) do
    Logger.info("Telnet listening on port #{port}")
    :ranch.start_listener(__MODULE__, :ranch_tcp, [{:port, port}], Telnet.Protocol, [])
  end

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args}
    }
  end
end
