defmodule TimescaleEcto do
  @moduledoc """
  Documentation for TimescaleEcto.
  """

  defmacro first(value, time) do
    quote do: fragment("first(?, ?)", unquote(value), unquote(time))
  end

  defmacro histogram(value, min, max, nbuckets) do
    quote do:
            fragment(
              "histogram(?, ?, ?, ?)",
              unquote(value),
              unquote(min),
              unquote(max),
              unquote(nbuckets)
            )
  end

  defmacro interpolate(value) do
    quote do: fragment("interpolate(?)", unquote(value))
  end

  defmacro interpolate(value, prev, next) do
    quote do: fragment("interpolate(?, ?, ?)", unquote(value), unquote(prev), unquote(next))
  end

  defmacro timescale_last(value, time) do
    quote do: fragment("last(?, ?)", unquote(value), unquote(time))
  end

  defmacro locf(value) do
    quote do: fragment("interpolate(?)", unquote(value))
  end

  defmacro locf(value, prev, treat_null_as_missing) do
    quote do:
            fragment(
              "interpolate(?, ?, ?)",
              unquote(value),
              unquote(prev),
              unquote(treat_null_as_missing)
            )
  end

  # add integer time inputs
  defmacro time_bucket(bucket_width, time) do
    quote do: fragment("time_bucket(?, ?)", unquote(bucket_width), unquote(time))
  end

  defmacro time_bucket(bucket_width, time, offset, origin) do
    quote do:
            fragment(
              "time_bucket(?, ?, ?, ?)",
              unquote(bucket_width),
              unquote(time),
              unquote(offset),
              unquote(origin)
            )
  end

  defmacro time_bucket_gapfill(bucket_width, time) do
    quote do:
    fragment(
      "time_bucket_gapfill(?, ?)",
      unquote(bucket_width),
      unquote(time)
    )
  end
end
