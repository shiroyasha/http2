defmodule Http2.Connection do
  require Logger
  use GenServer

  def start_link(listen_socket) do
    Logger.info "Starting connection"

    GenServer.start_link(__MODULE__, {listen_socket})
  end

  def init({listen_socket}) do
    Logger.info "Connection initialization"

    {:ok, {:listen_socket, listen_socket}}
  end

end
