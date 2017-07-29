defmodule Http2.Connection do
  require Logger
  use GenServer

  alias Http2.Frame

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

    # :gen_tcp.close(conn)

    accept(listen_socket)
  end

  def recv(conn) do
    case :gen_tcp.recv(conn, 0) do
      {:ok, data} ->
        Logger.info "===> Received #{inspect(data)}"

        respond(conn, data)

        recv(conn)
      {:error, :closed} ->
        Logger.info "Socked closed"

        :ok
    end
  end

  def respond(conn, "") do
    # do nothing
  end

  def respond(conn, @connection_preface <> data) do
    Logger.info "<=== Sending back ack"

    :gen_tcp.send(conn, Http2.Frame.Settings.ack)

    respond(conn, data)
  end

  def respond(conn, data) do
    {frame, unprocessed} = Frame.parse(data)

    if Frame.frame_type(frame) == :settings do
      Frame.Settings.parse_settings(frame.payload)
    else
      Logger.info "Byte size of the data #{byte_size(data)}"

      Logger.info "Frame: #{Frame.frame_type(frame)}"
      Logger.info "Frame: #{inspect(frame)}"

      Logger.info "Unprocessed: #{inspect(unprocessed)}"
    end
  end

end
