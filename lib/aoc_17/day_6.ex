defmodule Aoc17.Day6 do
  @doc ~S"""
    iex> Aoc17.Day6.part1("0 2 7 0")
    5
  """
  def part1(input) do
    input
    |> String.trim
    |> String.split
    |> Enum.map(&String.to_integer/1)
    |> Stream.iterate(&redistribute/1)
    |> Enum.reduce_while(MapSet.new, fn(banks, configurations) ->
      if MapSet.member?(configurations, banks) do
        {:halt, configurations}
      else
        {:cont, MapSet.put(configurations, banks)}
      end
    end)
    |> MapSet.size
  end

  @doc ~S"""
    iex> Aoc17.Day6.redistribute([0,2,7,0])
    [2, 4, 1, 2]

    iex> Aoc17.Day6.redistribute([2, 4, 1, 2])
    [3, 1, 2, 3]

    iex> Aoc17.Day6.redistribute([3, 1, 2, 3])
    [0, 2, 3, 4]

    iex> Aoc17.Day6.redistribute([0, 2, 3, 4])
    [1, 3, 4, 1]

    iex> Aoc17.Day6.redistribute([1, 3, 4, 1])
    [2, 4, 1, 2]
  """
  def redistribute(banks) do
    banks
    |> empty_largest
    |> do_redistribute
  end

  defp empty_largest(banks) do
    {largest, n} = banks
                   |> Enum.with_index
                   |> Enum.max_by(fn({blocks, n}) -> {blocks, n * -1} end)
    {largest, List.replace_at(banks, n, 0), n + 1}
  end

  defp do_redistribute({0, banks, _write_to}), do: banks

  defp do_redistribute({blocks, banks, write_to})
  when write_to == length(banks) do
    do_redistribute({blocks, banks, 0})
  end

  defp do_redistribute({blocks, banks, write_to})
  when write_to < length(banks) do
    do_redistribute({
      blocks - 1,
      List.update_at(banks, write_to, &(&1 + 1)),
      write_to + 1
    })
  end
end
