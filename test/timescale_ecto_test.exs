defmodule TimescaleEctoTest do
  use ExUnit.Case, async: true
  use Ecto.Migration
  import Ecto.Query
  import TimescaleEcto

  defmodule Repo do
    use Ecto.Repo, otp_app: :timescale_ecto, adapter: Ecto.Adapters.Postgres
  end

  defmodule State do
    use Ecto.Schema

    @primary_key false
    schema "states" do
      field(:device_name, :string)
      field(:temperature, :integer)
      field(:inserted_at, :utc_datetime)
    end
  end

  setup _ do
    {:ok, pid} = Postgrex.start_link(TimescaleEcto.Test.Helper.opts())

    {:ok, _} = Postgrex.query(pid, "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;", [])

    {:ok, _} = Postgrex.query(pid, "DROP TABLE IF EXISTS states", [])

    {:ok, _} =
      Postgrex.query(
        pid,
        "CREATE TABLE states (device_name varchar, temperature integer, inserted_at timestamp)",
        []
      )

    {:ok, _} =
      Postgrex.query(
        pid,
        "SELECT create_hypertable('states', 'inserted_at');",
        []
      )

    {:ok, _} = Repo.start_link()

    :ok
  end

  test "returns last value" do
    Repo.insert(%State{
      device_name: "hello",
      temperature: 12,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    query = from(state in State, select: timescale_last(state.temperature, state.inserted_at))

    results = query |> Repo.one()

    assert results == 12
  end

  test "returns last value for group" do
    Repo.insert(%State{
      device_name: "device_1",
      temperature: 12,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    Repo.insert(%State{
      device_name: "device_2",
      temperature: 14,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    Repo.insert(%State{
      device_name: "device_1",
      temperature: 25,
      inserted_at:
        DateTime.utc_now()
        |> DateTime.add(-310, :second)
        |> DateTime.truncate(:second)
    })

    Repo.insert(%State{
      device_name: "device_2",
      temperature: 27,
      inserted_at:
        DateTime.utc_now()
        |> DateTime.add(-310, :second)
        |> DateTime.truncate(:second)
    })

    query =
      from(state in State,
        select: %{
          device_name: state.device_name,
          last_value: timescale_last(state.temperature, state.inserted_at)
        },
        group_by: state.device_name
      )

      results = query |> Repo.all()

    assert results == [
             %{last_value: 12, device_name: "device_1"},
             %{device_name: "device_2", last_value: 14}
           ]
  end

  test "returns histogram" do
    Repo.insert(%State{
      device_name: "device_1",
      temperature: 12,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    Repo.insert(%State{
      device_name: "device_2",
      temperature: 12,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    query =
      from(state in State,
        select: %{
          histogram: histogram(state.temperature, 20, 60, 5)
        }
      )

    results = query |> Repo.all()

    assert results == [%{histogram: [2, 0, 0, 0, 0, 0, 0]}]
  end

  test "time bucket returns values grouped by time bucket" do
    Repo.insert(%State{
      device_name: "device_1",
      temperature: 12,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    Repo.insert(%State{
      device_name: "device_2",
      temperature: 14,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    Repo.insert(%State{
      device_name: "device_1",
      temperature: 25,
      inserted_at:
        DateTime.utc_now()
        |> DateTime.add(-310, :second)
        |> DateTime.truncate(:second)
    })

    Repo.insert(%State{
      device_name: "device_2",
      temperature: 27,
      inserted_at:
        DateTime.utc_now()
        |> DateTime.add(-310, :second)
        |> DateTime.truncate(:second)
    })

    query =
      from(state in State,
        select: %{
          time_bucket: time_bucket("5 minutes", state.inserted_at),
          average: type(avg(state.temperature), :integer)
        },
        group_by: time_bucket("5 minutes", state.inserted_at)
      )

    results = query |> Repo.all()

    assert [%{average: 13, time_bucket: _timebucket_1}, %{average: 26, time_bucket: _timebucket_2}] = results
  end

  # TODO: rethink this test
  test "time_bucket_gapfill returns values grouped by time bucket" do
    Repo.insert(%State{
      device_name: "device_1",
      temperature: 12,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    Repo.insert(%State{
      device_name: "device_2",
      temperature: 14,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })

    Repo.insert(%State{
      device_name: "device_1",
      temperature: 25,
      inserted_at:
        DateTime.utc_now()
        |> DateTime.add(-610, :second)
        |> DateTime.truncate(:second)
    })

    Repo.insert(%State{
      device_name: "device_2",
      temperature: 27,
      inserted_at:
        DateTime.utc_now()
        |> DateTime.add(-610, :second)
        |> DateTime.truncate(:second)
    })

    query =
      from(state in State,
        select: %{
          time_bucket: time_bucket_gapfill("5 minutes", state.inserted_at),
          average: type(avg(state.temperature), :integer),
          average_interpolated: interpolate(avg(state.temperature))
        },
        where: fragment("inserted_at > now () - interval '135 minutes'"),
        where: fragment("inserted_at < now () - interval '113 minutes'"),
        group_by: time_bucket_gapfill("5 minutes", state.inserted_at)
      )

    results = query |> Repo.all() |> Enum.map(fn s -> s.average_interpolated end)

    assert results == [nil, 26.0, 19.5, 13.0, nil]
  end
end
