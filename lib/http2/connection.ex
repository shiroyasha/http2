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
      conn: conn,
      buffer: ""
    }

    {:ok, state}
  end


  # ########################################
  # Incomming tcp data
  # ########################################

  def handle_info({:tcp, _port, data}, state) do
    new_state = consume(data, state)

    :inet.setopts(new_state.conn, active: :once)

    {:noreply, new_state}
  end

  def handle_info({:tcp_closed, _port}, state) do
    Logger.info "==== Closing tcp connection"

    {:stop, :normal, state}
  end


  # ########################################
  # Outgoing tcp data
  # ########################################

  def respond(data, state) do
    Logger.info "<=== Sending back #{inspect(data)}"

    :ok = :gen_tcp.send(state.conn, data)
  end


  # ########################################
  # Consuming raw data
  # ########################################

  def consume(@connection_preface <> data, state) do
    # empty settings frame
    respond(<<0::24, 4::8, 0::8, 0::1, 0::31>>, state)

    consume(data, state)
  end

  def consume(data, state) do
    case Frame.parse(state.buffer <> data) do
      {nil, unprocessed} ->
        %{ state | buffer: unprocessed }

      {frame, unprocessed} ->
        new_state = consume_frame(frame, state)

        consume(unprocessed, new_state)
    end
  end


  # ########################################
  # Consuming frames
  # ########################################

  def consume_frame(frame = %Frame{type: :data}, state) do
    Logger.info "===> data #{inspect(frame.payload)}"
    Logger.info "===> data #{inspect(frame.stream_id)}"

    # close the stream
    # sending header with END_STREAM and END_HEADERS set
    response_frame = <<4::24, 1::8, 5::8, 0::1, 1::31, frame.payload::binary>>

    respond(response_frame, state)

    state
  end

  def consume_frame(frame = %Frame{type: :header}, state) do
    header = Http2.Frame.Header.decode(frame)
    Logger.info inspect(frame)

    Logger.info "#{inspect(header)}"

    state
  end

  def consume_frame(frame = %Frame{type: :settings}, state) do
    Logger.info "===> settings #{inspect(frame)}"

    respond(Http2.Frame.Settings.ack, state)

    state
  end

  def consume_frame(frame, state) do
    Logger.info "===> Generic Frame #{inspect(frame)}"

    state
  end

end
