defmodule Http2.Connection do
  use GenServer
  require Logger
  alias Http2.Frame

  # Default connection "fast-fail" preamble string as defined by the spec.
  @connection_preface "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"

  def start_link(socket) do
    GenServer.start_link(__MODULE__, {socket}, [])
  end

  def init({socket}) do
    {:ok, conn} = :gen_tcp.accept(socket)
    :inet.setopts(conn, active: :once)

    state = %{
      socket: socket,
      conn: conn
    }

    {:ok, state}
  end

  def handle_info({:tcp, _port, data}, state) do
    Logger.info "===> #{inspect(data)}"

    new_state = consume(data, state)

    :inet.setopts(new_state.conn, active: :once)

    {:noreply, new_state}
  end

  def handle_info(other, state) do
    Logger.info "Unhandled #{inspect(other)}"
  end

  def consume(@connection_preface <> data, state) do
    Logger.info "<=== Sending back ack"

    :gen_tcp.send(state.conn, Http2.Frame.Settings.ack)

    consume(data, state)
  end

  def consume(data, state) do
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
