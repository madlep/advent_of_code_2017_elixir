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

    assert parse(parser, "pbga (66)") == %Parser.Result{value: ["pbga", 66, []], rest: ""}
    assert parse(parser, "fwft (72) -> ktlj, cntj, xhth") ==
      %Parser.Result{value: ["fwft", 72, [["ktlj"], ["cntj"], ["xhth"]]], rest: ""}
  end

  test "can parse AOC day 7 multiple lines" do
    import Parser

    parser = sep_by(
      word()
      |> skip(space())
      |> between(char("("), integer(), char(")"))
      |> option(
        skip(trim(string("->")))
        |> sep_by(word(), trim(char(",")), at_least_one: true)
      ),
      newline()
    )

    assert parse(parser, "pbga (66)\nfwft (72) -> ktlj, cntj, xhth") ==
      %Parser.Result{value: [
        [
          ["pbga", 66, [] ],
          ["fwft", 72, [[ "ktlj" ],[ "cntj"],[  "xhth" ]]]
        ]
      ], rest: "" }
  end
end
