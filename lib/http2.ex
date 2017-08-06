defmodule Http2 do
  require Logger
  use Supervisor

  @max_connection_restarts 1000
  @default_connection_count 10

  def start_link(port, opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    connections = Keyword.get(opts, :connections, @default_connection_count)
    handler_module = Keyword.get(opts, :handler)

    {:ok, supervisor} = Supervisor.start_link(__MODULE__, {port, opts}, name: name)

    # document me :)
    tcp_options = [
      :binary,
      {:reuseaddr, true},
      {:packet, :raw},
      {:active, false}
    ]

    {:ok, listen_socket} = :gen_tcp.listen(port, tcp_options)

    spawn_link fn ->
      acceptor(handler_module, listen_socket, supervisor)
    end

    {:ok, supervisor}
  end

  def acceptor(handler_module, listen_socket, supervisor) do
    {:ok, conn} = :gen_tcp.accept(listen_socket)

    {:ok, pid} = Supervisor.start_child(supervisor, [handler_module, conn])

    # send incomming data to the new worker
    :gen_tcp.controlling_process(conn, pid)

    acceptor(handler_module, listen_socket, supervisor)
  end

  def init({port, opts}) do
    children = [
      worker(Http2.Connection, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one, max_restarts: @max_connection_restarts)
  end

end
