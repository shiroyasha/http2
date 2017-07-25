defmodule Http2.Connection do
  require Logger
  use GenServer

  @connection_preface "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"

  def start_link(listen_socket) do
    GenServer.start_link(__MODULE__, {listen_socket})
  end

  def init({listen_socket}) do
    spawn(fn -> accept(listen_socket) end)

    {:ok, {:listen_socket, listen_socket}}
  end

  def accept(listen_socket) do
    {:ok, conn} = :gen_tcp.accept(listen_socket)

    recv(conn)

    :gen_tcp.close(conn)

    accept(listen_socket)
  end

  def recv(conn) do
    case :gen_tcp.recv(conn, 0) do
      {:ok, data} ->
        Logger.info(inspect(data))

        :gen_tcp.send(conn, response(data))
      {:error, :closed} ->
        :ok
    end
  end

  # Received connection preface from the client
  # Sending back Settings frame
  def response(@connection_preface) do
    # based on https://http2.github.io/http2-spec/#rfc.section.6.5.1
    <<0::24, 4::8, 0::8, 0::1, 0::31>>
  end

  # Received unknown data from the client
  # Sending back echo
  def response(data) do
    data
  end

  def handle_info(thing, state) do
    Logger.info(inspect(thing))

    {:ok, state}
  end

end
