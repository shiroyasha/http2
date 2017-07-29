defmodule HelloHttp2 do
  use Application

  def start(_type, _args) do
    certfile = Application.app_dir(:hello_http2, "/priv/cert.pem")
    keyfile = Application.app_dir(:hello_http2, "/priv/key.pem")

    Http2.start_link(
      8443,
      certfile: certfile,
      keyfile: keyfile,
      connections: 1000
    )
  end
end
