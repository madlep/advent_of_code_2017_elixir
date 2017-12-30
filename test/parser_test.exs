defmodule ParserTest do
  use ExUnit.Case, async: true
  doctest Parser
  import Parser

  defp line_parser do
    word()
    |> skip(space())
    |> between(char("("), integer(), char(")"))
    |> option(
      skip(trim(string("->")))
      |> sep_by(word(), trim(char(",")), unlist: true)
    )
  end

  test "can parse AOC day 7 lines" do
    assert parse(line_parser(), "pbga (66)") ==
      %Parser.Result{value: ["pbga", 66, []], rest: ""}

    assert parse(line_parser(), "fwft (72) -> ktlj, cntj, xhth") ==
      %Parser.Result{value: ["fwft", 72, ["ktlj", "cntj", "xhth"]], rest: ""}
  end

  test "can parse AOC day 7 multiple lines" do
    parser = sep_by(line_parser(), newline())

    assert parse(parser, "pbga (66)\nfwft (72) -> ktlj, cntj, xhth") ==
      %Parser.Result{value: [
        [
          ["pbga", 66, [] ],
          ["fwft", 72, [ "ktlj", "cntj", "xhth"]]
        ]
      ], rest: "" }
  end
end
