Mix.install([:jason])

defmodule Git do
  @moduledoc """
  Provides functions for interacting with Git and processing Git log output as JSON.
  """
  def log(branch_name) do
    {output, 0} =
      System.cmd("git", [
        "log",
        ~s(--pretty=format:{%n  "commit": "%H",%n  "author": "%an <%ae>",%n  "date": "%aI",%n  "message": "%f"%n},),
        branch_name
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

  @time_window 60

  def calculate(branch_name) do
    commits = Git.log(branch_name)

    case commits do
      [] ->
        {:error, "No commits found"}

      _ ->
        commits
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [a, b] ->
          min(NaiveDateTime.diff(a.date, b.date, :millisecond) / :timer.minutes(1), @time_window)
        end)
        |> Enum.sum()
        # to account for the "initial" time window
        |> Kernel.+(@time_window)
        |> then(fn minutes -> {:ok, minutes} end)
    end
  end

  def print_totals(branches) do
    results =
      branches
      |> Enum.map(&calculate/1)
      |> Enum.reduce({:ok, 0}, fn
        {:ok, minutes}, {:ok, acc} -> {:ok, acc + minutes}
        {:error, msg}, _acc -> {:error, msg}
      end)

    case results do
      {:ok, total_minutes} ->
        hours = floor(total_minutes / 60)
        minutes = round(rem(floor(total_minutes), 60))

        IO.puts("Estimated time spent: #{hours} hours and #{minutes} minutes")

      {:error, msg} ->
        IO.puts("Error: #{msg}")
    end
  end
end

GitHours.print_totals(System.argv())
