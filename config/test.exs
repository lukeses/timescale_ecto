use Mix.Config

config :timescale_ecto, TimescaleEctoTest.Repo,
  database: "timescale_ecto_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

# Print only warnings and errors during test
config :logger, level: :warn
