defmodule ParserTest do
  use ExUnit.Case, async: true
  doctest Parser

  test "can parse AOC day 7 lines" do
    import Parser
    line = "pbga (66)"

    parser = word() |> skip(space()) |> between(char("("), integer(), char(")"))

    assert parse(parser, line) == {["pbga", 66], ""}
  end
end
