{:ok, _} = Application.ensure_all_started(:ecto_sql)

defmodule TimescaleEcto.Test.Helper do
  def opts do
    [
      hostname: "localhost",
      username: "postgres",
      password: "postgres",
      database: "timescale_ecto_test"
    ]
  end
end

ExUnit.start()
