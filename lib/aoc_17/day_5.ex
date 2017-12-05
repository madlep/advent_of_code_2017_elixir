defmodule Aoc17.Day5 do
  @doc ~S"""
    iex> Aoc17.Day5.part1("0\n3\n0\n1\n-3\n")
    5
  """
  def part1(input) do
    input
    |> parse
    |> build_jmps
    |> jmp_escape(fn(jmp) -> jmp + 1 end)
  end

  @doc ~S"""
    iex> Aoc17.Day5.part2("0\n3\n0\n1\n-3\n")
    10
  """
  def part2(input) do
    input
    |> parse
    |> build_jmps
    |> jmp_escape(fn
      (jmp) when jmp >= 3 -> jmp - 1
      (jmp) -> jmp + 1
    end)
  end

  defp parse(input) do
    input
    |> String.trim
    |> String.split("\n")
    |> Enum.map(&parse_int/1)
  end

  defp parse_int(str) do
    {int, ""} = Integer.parse(str)
    int
  end

  defp build_jmps(jmp_list) do
    jmp_list
    |> Enum.with_index
    |> Enum.reduce(%{}, fn({jmp, i}, jmps) -> Map.put(jmps, i, jmp) end)
  end

  defp jmp_escape(jmps, incr), do: jmp_escape(0, jmps, 0, incr)

  defp jmp_escape(i, jmps, count, incr) do
    case jmps[i] do
      nil   -> count
      jmp -> jmp_escape(i + jmp, Map.update!(jmps, i, incr), count + 1, incr)
    end
  end
end
