defmodule Http2.Integration.HelloWorldTest do
  use ExUnit.Case

  defmodule Connection do
    def init(opts) do
      :ok
    end

    def consume(frame) do
      IO.puts "YAY"
      IO.puts "payload: #{frame.payload}"

      "Hello World"
    end
  end

  setup do
    {:ok, server} = Http2.start_link(8888,
      connections: 2,
      handler: Connection
    )

    :timer.sleep(1000)

    on_exit fn ->
      Process.exit(server, :kill)
    end

    {:ok, server: server}
  end

  test "hello world test", context do
    {:ok, conn} = :gen_tcp.connect({127,0,0,1}, 8888, [:binary, {:active,false}])
    :timer.sleep(1000)

    IO.puts "Sending preface"
    :gen_tcp.send(conn, "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n")
    :timer.sleep(1000)

    {:ok, data} = :gen_tcp.recv(conn, 0)
    assert data == <<0, 0, 0, 4, 0, 0, 0, 0, 0>>

    IO.puts "Sending data frame"
    :gen_tcp.send(conn, <<4::24, 0::8, 0::8, 0::1, 1::31>> <> "test")
    :timer.sleep(1000)

    # expect headers
    {:ok, payload} = :gen_tcp.recv(conn, 0)

    expected_headers = <<0, 0, 4, 1, 5, 0, 0, 0, 1, 116, 101, 115, 116>>
    expected_data    = <<0, 0, 11, 0, 5, 0, 0, 0, 1>> <> "Hello World"

    assert payload == expected_headers <> expected_data

    :gen_tcp.close(conn)
  end

  test "hello world test", context do
    {:ok, conn} = Http2.Client.start_link(host: "localhost", port: 8888)

    {:ok, response} = Http2.Client.request(conn, body: "", headers: [
      ":method": "GET",
      ":path": "/",
      ":scheme": "http",
      "user-agent": "elixir-http2-client/0.0.1"
    ])

    assert response.headers == [{"content-type": "text/html"}]
    assert response.body == "Hello World"

    Http2.Client.close(conn)
  end

end
