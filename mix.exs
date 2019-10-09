defmodule TimescaleEcto.MixProject do
  use Mix.Project

  def project do
    [
      app: :timescale_ecto,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0", optional: true, only: :test},
      {:postgrex, "~> 0.14", only: :test},
      {:scribe, "~> 0.10"}
    ]
  end
end
