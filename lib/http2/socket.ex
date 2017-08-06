defmodule Http2.Socket do
  use GenServer
  require Logger

  def start_link(handler_module, socket) do
    GenServer.start_link(__MODULE__, {handler_module, socket}, [])
  end

end
