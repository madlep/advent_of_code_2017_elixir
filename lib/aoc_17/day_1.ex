defmodule Aoc17.Day1 do
  @doc """
    iex> Aoc17.Day1.part1("1122")
    3

    iex> Aoc17.Day1.part1("1111")
    4

    iex> Aoc17.Day1.part1("1234")
    0

    iex> Aoc17.Day1.part1("91212129")
    9
  """
  def part1(input) do
    part1(input, input, 0)
  end

  defp part1(_input, "", sum), do: sum

  defp part1(input, <<n::utf8, n::utf8, rest::binary>>, sum) do
    {n_int, ""} = Integer.parse(<<n>>)
    part1(input, <<n, rest::binary>>, sum + n_int)
  end

  defp part1(<<n::utf8, _rest_input::binary>> = input, <<n::utf8>>, sum) do
    {n_int, ""} = Integer.parse(<<n>>)
    part1(input, "", sum + n_int)
  end

  defp part1(<<_n2::utf8, _rest_input::binary>> = input, <<_n1::utf8>>, sum) do
    part1(input, "", sum)
  end

  defp part1(input, <<_n1::utf8, n2::utf8, rest::binary>>, sum) do
    part1(input, <<n2, rest::binary>>, sum)
  end

  @doc """
    iex> Aoc17.Day1.part2("1212")
    6

    iex> Aoc17.Day1.part2("1221")
    0

    iex> Aoc17.Day1.part2("123425")
    4

    iex> Aoc17.Day1.part2("123123")
    12

    iex> Aoc17.Day1.part2("12131415")
    4
  """
  def part2(input) do
    l = String.length(input)
    {s1, s2} = String.split_at(input, div(l, 2))
    part2(s1, s2, 0) + part2(s2, s1, 0)
  end

  defp part2("", "", sum), do: sum

  defp part2(<<n::utf8, rest1::binary>>, <<n::utf8, rest2::binary>>, sum) do
    {n_int, ""} = Integer.parse(<<n>>)
    part2(rest1, rest2, sum + n_int)
  end

  defp part2(<<_n1::utf8, rest1::binary>>, <<_n2::utf8, rest2::binary>>, sum) do
    part2(rest1, rest2, sum)
  end
end
