Mix.install([:jason])

defmodule Git do
  @moduledoc """
  Provides functions for interacting with Git and processing Git log output as JSON.
  """
  def log() do
    {output, 0} =
      System.cmd("git", [
        "log",
        ~s(--pretty=format:{%n  "commit": "%H",%n  "author": "%an <%ae>",%n  "date": "%aI",%n  "message": "%f"%n},)
      ])

    output
    # remove trailing comma because Jason is RFC 8259 compliant
    |> String.trim_trailing(",")
    |> then(fn str -> "[#{str}]" end)
    |> Jason.decode!()
    |> Enum.map(fn commit ->
      Map.update(commit, "date", nil, &NaiveDateTime.from_iso8601!/1)
    end)
    # change string keys to atoms
    |> Enum.map(fn commit ->
      for {key, val} <- commit, into: %{}, do: {String.to_atom(key), val}
    end)
  end
end
