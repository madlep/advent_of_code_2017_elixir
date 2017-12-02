defmodule Aoc17.Day2 do
  @big    99999999999999999999999999
  @small -99999999999999999999999999
  @doc ~S"""
    iex> Aoc17.Day2.part1("5 1 9 5\n7 5 3\n2 4 6 8")
    18
  """
  def part1(input) do
    input
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
    |> Enum.map(&min_max/1)
    |> Enum.map(&diff/1)
    |> Enum.sum
  end

  @doc ~S"""
    iex> Aoc17.Day2.part2("5 9 2 8\n9 4 7 3\n3 8 6 5")
    9
  """
  def part2(input) do
    input
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
    |> Enum.map(&divisible_pair/1)
    |> Enum.map(&div_pair/1)
    |> Enum.sum
  end

  defp parse_line(line) do
    line
    |> String.split
    |> Enum.map(&parse_int(&1))
  end

  defp parse_int(string) do
    {int, ""} = Integer.parse(string)
    int
  end

  defp min_max(nums) do
    nums
    |> Enum.reduce({@small, @big}, fn(n, {big, small}) ->
      {max(big, n), min(small, n)}
    end)
  end

  defp diff({big, small}), do: big - small

  defp divisible_pair(list) do
    for n1 <- list, n2 <- list, rem(n1, n2) == 0, n1 != n2 do
      {n1, n2}
    end
  end

  defp div_pair([{n1, n2}]), do: div(n1, n2)
end
