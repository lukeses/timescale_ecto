# TimescaleEcto

A small set of functions used in TimescaleDB extension.

As a first step, you need to add a migration:

```Elixir
  def change do
    execute "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;", "DROP EXTENSION timescaledb"
  end
```

Then you need to require the module with functions:

```Elixir
import TimescaleEcto
```

Example usage:

```Elixir
    query =
      from(state in State,
        select: %{
          device_name: state.device_name,
          last_value: timescale_last(state.temperature, state.inserted_at)
        },
        group_by: state.device_name
      )

      results = query |> Repo.all()
```

TODO:

* add more tests
* setup CI
* add to Hex
