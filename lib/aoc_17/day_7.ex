defmodule Aoc17.Day7 do

  defmodule Disc do
    defstruct [
      name: nil,
      weight: nil,
      parent: nil
    ]
  end

  @doc ~S"""
    iex> Aoc17.Day7.part1("pbga (66)\nxhth (57)\nebii (61)\nhavc (66)\nktlj (57)\nfwft (72) -> ktlj, cntj, xhth\nqoyq (66)\npadx (45) -> pbga, havc, qoyq\ntknk (41) -> ugml, padx, fwft\njptl (61)\nugml (68) -> gyxo, ebii, jptl\ngyxo (61)\ncntj (57)")
    "tknk"
  """
  def part1(input) do
    input
    |> parse
    |> build_registry
    |> find_root
  end

  defp parse(input) do
    case Parser.parse(lines_parser(), input) do
      %Parser.Result{value: [lines], rest: ""} -> lines
      result -> raise "didn't get %Parser.Result{} result=#{inspect(result)}"
    end
  end

  defp line_parser do
    import Parser
    word()
    |> skip(space())
    |> between(char("("), integer(), char(")"))
    |> option(
      skip(trim(string("->")))
      |> sep_by(word(), trim(char(",")), unlist: true)
    )
  end

  defp lines_parser do
    import Parser
    sep_by(line_parser(), newline())
  end

  defp build_registry(discs) do
    discs
    |> Enum.reduce(%{}, &add_disc/2)
  end

  defp add_disc([name, weight, children], registry) do
    registry = registry
    |> Map.update(
      name,
      %Disc{name: name, weight: weight},
      fn (%Disc{name: ^name, weight: current_weight} = disc) ->
        %Disc{disc|weight: current_weight || weight}
      end
    )

    children
    |> Enum.reduce(registry, &set_parent(&1, name, &2))
  end

  defp set_parent(name, parent, registry) do
    registry
    |> Map.update(
      name,
      %Disc{name: name, parent: parent},
      fn (%Disc{name: ^name} = disc) -> %Disc{disc|parent: parent} end
    )
  end

  defp find_root(registry) do
    registry
    |> Enum.find(
      fn ({_k, %Disc{parent: nil}}) -> true
         ({_k, _v}) -> false
    end)
    |> elem(0)
  end
end
