defmodule LsProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :ls_proxy,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: LsProxy.CLI],
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {LsProxy.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mojito, "~> 0.2.0"},
      {:jason, "~> 1.1"},
      {:logger_file_backend, "~> 0.0.10"},
      # runtime: false because for an escript we need to manually start it
      {:erlexec, "~> 1.10.0", runtime: false},
      {:utils, path: "../utils"},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false}
    ]
  end
end
