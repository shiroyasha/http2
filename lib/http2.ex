defmodule Http2 do
  require Logger
  use Supervisor

  @max_connection_restarts 1000
  @default_connection_count 10

  def start_link(port, opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    connections = Keyword.get(opts, :connections, @default_connection_count)

    {:ok, supervisor} = Supervisor.start_link(__MODULE__, {port, opts}, name: name)

    (1..connections) |> Enum.each(fn index ->
      Logger.info "Starting connection #{index}"
      Supervisor.start_child(supervisor, [])
    end)

    {:ok, supervisor}
  end

  def init({port, opts}) do
    {:ok, certfile} = Keyword.fetch(opts, :certfile)
    {:ok, keyfile} = Keyword.fetch(opts, :keyfile)
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, {:packet, 0}, {:active, false}])

    children = [
      worker(Http2.Connection, [listen_socket], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one, max_restarts: @max_connection_restarts)
  end

end
