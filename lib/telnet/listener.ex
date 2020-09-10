defmodule Telnet.Listener do
  def start_link(port) do
    IO.puts("Telnet listener starting on port #{port}")
    :ranch.start_listener(__MODULE__, :ranch_tcp, [{:port, port}], Telnet.Protocol, [])
  end

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args}
    }
  end
end
