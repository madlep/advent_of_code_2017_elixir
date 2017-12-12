defmodule ParserTest do
  use ExUnit.Case, async: true
  doctest Parser

  test "can parse AOC day 7 lines" do
    import Parser

    parser = word()
             |> skip(space())
             |> between(char("("), integer(), char(")"))
             |> option(
               skip(trim(string("->")))
               |> sep_by(word(), trim(char(",")), at_least_one: true)
             )

    assert parse(parser, "pbga (66)") == {["pbga", 66, []], ""}
    assert parse(parser, "fwft (72) -> ktlj, cntj, xhth") ==
      {["fwft", 72, ["ktlj", "cntj", "xhth"]], ""}
  end
end
