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

defmodule GitHours do
  @doc """
  Calculates total the duration between commits based on a time window in minutes.

  If there are no commits, returns `{:error, "No commits found"}`. If there is only one
  commit, returns `{:ok, time_window}`. Otherwise returns a `Duration` representing the
  total time between commits.

  ## Parameters
  - `time_window`: The time window (in minutes) to use for the calculation
  """
  def calculate(time_window) do
    commits = Git.log()

    case commits do
      [] ->
        {:error, "No commits found"}

      [_only_commit] ->
        {:ok, time_window}

      _ ->
        commits
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [a, b] ->
          min(NaiveDateTime.diff(a.date, b.date, :millisecond) / 60_000, time_window)
        end)
        |> Enum.sum()
        # to account for the "initial" time window
        |> Kernel.+(time_window)
        |> then(fn minutes -> {:ok, minutes} end)
    end
  end
end

# use a 1hr time window
case GitHours.calculate(60) do
  {:ok, minutes} ->
    IO.puts(
      "estimated time spent working on this git branch: #{Float.round(minutes / 60, 2)} hours"
    )

  {:error, msg} ->
    IO.puts("Error: #{msg}")
end
