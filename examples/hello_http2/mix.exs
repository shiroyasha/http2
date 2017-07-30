defmodule HelloHttp2.Mixfile do
  use Mix.Project

  def project do
    [app: :hello_http2,
     version: "0.0.1",
     elixir: "~> 1.5",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger], mod: {HelloHttp2, []}]
  end

  defp deps do
    [{:http2, path: "../.."}]
  end
end
