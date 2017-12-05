defmodule Aoc17.Day4 do
  @doc ~S"""
    iex> Aoc17.Day4.part1("aa bb cc dd ee\naa bb cc dd aa\naa bb cc dd aaa")
    2
  """
  def part1(input) do
    input
    |> String.split("\n")
    |> Enum.count(&valid_part1?/1)
  end

  @doc ~S"""
    iex> Aoc17.Day4.part2("abcde fghij\nabcde xyz ecdab\na ab abc abd abf abj\niiii oiii ooii oooi oooo\noiii ioii iioi iiio")
    3
  """
  def part2(input) do
    input
    |> String.split("\n")
    |> Enum.count(&valid_part2?/1)
  end

  @doc ~S"""
    iex> Aoc17.Day4.valid_part1?("aa bb cc dd ee")
    true

    iex> Aoc17.Day4.valid_part1?("aa bb cc dd aa")
    false

    iex> Aoc17.Day4.valid_part1?("aa bb cc dd aaa")
    true

  """
  def valid_part1?(input) do
    input
    |> String.split
    |> no_dups?
  end

  @doc ~S"""
    iex> Aoc17.Day4.valid_part2?("abcde fghij")
    true

    iex> Aoc17.Day4.valid_part2?("abcde xyz ecdab")
    false

    iex> Aoc17.Day4.valid_part2?("a ab abc abd abf abj")
    true

    iex> Aoc17.Day4.valid_part2?("iiii oiii ooii oooi oooo")
    true

    iex> Aoc17.Day4.valid_part2?("oiii ioii iioi iiio")
    false
  """
  def valid_part2?(input) do
    words = input |> String.split
    no_dups?(words) && no_anagrams?(words)
  end

  defp no_dups?(words), do: no_dups?(words, MapSet.new)
  defp no_dups?([], _set), do: true
  defp no_dups?([word|words], set) do
    case MapSet.member?(set, word) do
      true -> false
      false -> no_dups?(words, MapSet.put(set, word))
    end
  end

  defp no_anagrams?(words) do
    words
    |> Enum.reject(&(String.length(&1) == 1))
    |> Enum.map(&sort_str/1)
    |> no_dups?
  end

  defp sort_str(str) do
    str
    |> String.graphemes
    |> Enum.sort
    |> to_string
  end
end
