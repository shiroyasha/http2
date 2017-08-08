defmodule Http2.Connection do
  use GenServer
  require Logger
  alias Http2.Frame

  defstruct type: nil,                # Connection type - :server or :client.
            buffer: "",               # Buffer for incomming bytes.
            hpack_table: nil,         # Pid of the HPack.Table used for encoding/decoding headers.
            state_name: :handshake,   # Current state of the connection. One of (:handshake, :connected, :continuation, :shutdown).
            controlling_process: nil, # Pid of the controlling process. Every incomming frame is sent to this process.
            socket: nil               # TCP or SSL socket.


  # Default connection "fast-fail" preamble string as defined by the spec.
  @connection_preface   "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"

  # maximum size of the hpack table
  @max_hpack_table_size 1000


  #
  # start_link
  #
  # A connection can be started for either a server or a client.
  #
  # For server connections, you need to pass:
  #  - controlling_process - PID of the process that will receive frames
  #  - socket - a socket that was connected to either tcp or ssl
  #
  # For client connections, you need to pass:
  #  - controlling_process - PID of the process that will receive frames
  #  - host - hostname of the remote server
  #  - port - port of the remote server
  #

  def start_link(:server, controlling_process, socket) do
    GenServer.start_link(__MODULE__, {:server, controlling_process, socket}, [])
  end

  def start_link(:client, controlling_process, host, port) do
    GenServer.start_link(__MODULE__, {:client, controlling_process, host, port}, [])
  end


  #
  # Private gen_server interface.
  #

  def init({:server, controlling_process, socket}) do
    :inet.setopts(socket, active: :once)

    {:ok, hpack_table} = HPack.Table.start_link(@max_hpack_table_size)

    state = %__MODULE__{
      type: :client,
      buffer: "",
      hpack_table: hpack_table,
      state_name: :handshake,
      controlling_process: controlling_process,
      socket: socket
    }

    {:ok, state}
  end

  def init({:client, controlling_process, host, port}) do
    {:ok, socket} = :gen_tcp.connect(host, port, [:binary, {:active,false}])

    {:ok, hpack_table} = HPack.Table.start_link(@max_hpack_table_size)

    state = %__MODULE__{
      type: :client,
      buffer: "",
      hpack_table: hpack_table,
      state_name: :handshake,
      controlling_process: controlling_process,
      socket: socket
    }

    {:ok, state}
  end

  # ########################################
  # Incomming tcp data
  # ########################################

  def handle_info({:tcp, _port, data}, state) do
    if state.state_name == :shutdown do
      {:stop, :normal, state}
    else
      new_state = consume(data, state)

      if new_state.state_name != :shutdown do
        :inet.setopts(new_state.conn, active: :once)

        {:noreply, new_state}
      else
        Logger.info "==== Shutdown"

        {:stop, :normal, new_state}
      end
    end
  end

  def handle_info({:tcp_closed, _port}, state) do
    IO.puts "TCP closed"

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

        # stop consuming and shutdown
        if new_state.state_name == :shutdown do
          new_state
        else
          consume(unprocessed, new_state)
        end
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
    respond(<<4::24, 1::8, 5::8, 0::1, 1::31, frame.payload::binary>>,  state)

    response_msg = state.handler_module.consume(frame)

    respond(<<byte_size(response_msg)::24, 0::8, 5::8, 0::1, 1::31>> <> response_msg, state)

    state
  end

  def consume_frame(frame = %Frame{type: :header}, state) do
    header = Http2.Frame.Header.decode(frame, state.hpack_table)

    Logger.info inspect(frame)
    Logger.info "#{inspect(header)}"

    p = HPack.encode(header.header_block_fragment, state.hpack_table)

    response_frame = %Http2.Frame{
      len: byte_size(p),
      type: :header,
      flags: 5, # end headers, end_stream
      stream_id: frame.stream_id,
      payload: p
    }

    respond(Http2.Frame.serialize(response_frame), state)

    state
  end

  def consume_frame(frame = %Frame{type: :settings}, state) do
    Logger.info "===> settings #{inspect(frame)}"

    respond(Http2.Frame.Settings.ack, state)

    state
  end

  def consume_frame(frame = %Frame{type: :ping}, state) do
    Logger.info "===> ping #{inspect(frame)}"

    ping = Http2.Frame.Ping.decode(frame)

    unless ping.flags.ack? do
      response_frame = %Http2.Frame{
        len: byte_size(ping.data),
        type: :ping,
        flags: 1, # ack
        stream_id: frame.stream_id,
        payload: ping.data
      }

      respond(Http2.Frame.serialize(response_frame), state)
    end

    state
  end

  def consume_frame(frame = %Frame{type: :go_away}, state) do
    Logger.info "===> go_away #{inspect(frame)}"

    :gen_tcp.close(state.conn)

    %{ state | state_name: :shutdown }
  end

  def consume_frame(frame = %Frame{type: :continuation}, state) do
    Logger.info "===> continuation #{inspect(frame)}"

    continuation = Http2.Frame.Continuation.decode(frame, state.hpack_table)

    # do nothing

    state
  end

  def consume_frame(frame, state) do
    Logger.info "===> Generic Frame #{inspect(frame)}"

    state
  end

end
