defmodule Parser do
  def parse(parser, input) do
    case parser.(input) do
      {result, rest} -> {result |> deep_reverse, rest}
      :nomatch -> :nomatch
    end
  end

  defp deep_reverse(maybe_enum) do
    try do
      maybe_enum
      |> Enum.reverse
      |> Enum.map(&deep_reverse/1)
    rescue
      Protocol.UndefinedError -> maybe_enum
    end
  end

  defp null(), do: fn(input) -> {[], input} end

  defp build_parser(parser, parser_fn) do
    fn(input) ->
      case parser.(input) do
        {prior_result, new_input} ->
          case parser_fn.(new_input) do
            {:noresult, rest} -> {prior_result, rest}
            {result, rest}    -> {[result|prior_result], rest}
            :nomatch          -> :nomatch
          end
        :nomatch -> :nomatch
      end
    end
  end

  @doc ~S"""
  parse a specified character

  iex> import Parser
  iex> char("f") |> parse("foobar")
  {["f"], "oobar"}
  iex> char("f") |> char("o") |> parse("foobar")
  {["f", "o"], "obar"}
  iex> char("X") |> parse("foobar")
  :nomatch
  """
  def char(parser \\ null(), c) do
    build_parser(parser, fn(input) ->
      case anychar().(input) do
        {[^c], rest} -> {c, rest}
        {_not_c, _rest} -> :nomatch
        :nomatch -> :nomatch
      end
    end)
  end

  @doc ~S"""
  parse any single alpha character

  iex> import Parser
  iex> anychar() |> parse("foobar")
  {["f"], "oobar"}
  iex> anychar() |> anychar() |> parse("foobar")
  {["f", "o"], "obar"}
  iex> anychar() |> parse("@#$%")
  {["@"], "#$%"}
  iex> anychar() |> parse("")
  :nomatch
  """
  def anychar(parser \\ null()) do
    build_parser(parser, fn
      (<<c::utf8, rest::binary>>) -> {<<c>>, rest}
      (_rest) -> :nomatch
    end)
  end

  @doc ~S"""
  parse an alphabetic character (a-z, A-Z)

  iex> import Parser
  iex> alpha() |> parse("foobar")
  {["f"], "oobar"}
  iex> alpha() |> alpha() |> parse("foobar")
  {["f", "o"], "obar"}
  iex> alpha() |> parse("@#$%")
  :nomatch
  """
  def alpha(parser \\ null()) do
    fn(input) ->
      {prior_result, new_input} = parser.(input)
      case anychar().(new_input) do
        {[c], rest} when ("a" <= c  and c <= "z") or ("A" <= c and c <= "Z") ->
          {[c|prior_result], rest}
        {_not_alpha, _rest} -> :nomatch
        :nomatch -> :nomatch
      end
    end
  end

  @doc ~S"""
  match many parsers

  iex> import Parser
  iex> many(alpha()) |> parse("foo bar baz")
  {[["f", "o", "o"]], " bar baz"}
  """
  def many(parser \\ null(), parser2) do
    build_parser(parser, fn(input) ->
      do_many(input, parser2, [])
    end)
  end

  defp do_many(input, parser, result) do
    case parser.(input) do
      {[parsed], rest} -> do_many(rest, parser, [parsed|result])
      :nomatch       -> {result, input}
    end
  end

  @doc ~S"""
  match a word

  iex> import Parser
  iex> word() |> parse("foo bar baz")
  {["foo"], " bar baz"}
  iex> word() |> parse("foo+bar")
  {["foo"], "+bar"}
  iex> word() |> parse("1+2")
  :nomatch
  """
  def word(parser \\ null()) do
    build_parser(parser, fn(input) ->
      {[result], rest} = many(alpha()).(input)
      case result |> Enum.reverse |> Enum.join do
        "" -> :nomatch
        word -> {word, rest}
      end
    end)
  end

  @doc ~S"""
  match a parser between two other parsers (e.g. term between brackets etc)

  iex> import Parser
  iex> between(char("("), word(), char(")")) |> parse("(foo)bar")
  {["foo"], "bar"}
  iex> between(char("("), word(), char(")")) |> parse("(foo]bar")
  :nomatch
  """
  def between(parser \\ null(), parser_left, parser2, parser_right) do
    build_parser(parser, fn(input) ->
      with {[], rest}       <- ignore(parser_left).(input),
           {[result], rest} <- parser2.(rest),
           {[], rest}       <- ignore(parser_right).(rest),
        do: {result, rest}
    end)
  end

  @doc ~S"""
  iex> import Parser
  iex> ignore(char("f")) |> char("o") |> parse("foobar")
  {["o"], "obar"}
  iex> ignore(char("x")) |> char("o") |> parse("foobar")
  :nomatch
  """
  def ignore(parser \\ null(), parser2) do
    build_parser(parser, fn(input) ->
      case parser2.(input) do
        {_result, rest} -> {:noresult, rest}
        :nomatch        -> :nomatch
      end
    end)
  end

  @doc ~S"""
  parse an integer
  iex> import Parser
  iex> integer() |> parse("123 abc")
  {[123], " abc"}
  iex> integer() |> parse("-123 abc")
  {[-123], " abc"}
  """
  def integer(parser \\ null()) do
    build_parser(parser, fn(input) ->
      do_integer(input, :unsigned)
    end)
  end

  defp do_integer(<<"-", c::utf8, rest::binary>>, :unsigned) when ?1 <= c and c <= ?9 do
    do_integer(rest, (c - ?0) * -1)
  end

  defp do_integer(<<c::utf8, rest::binary>>, :unsigned) when ?1 <= c and c <= ?9 do
    do_integer(rest, c - ?0)
  end

  defp do_integer(_rest, :unsigned), do: :nomatch

  defp do_integer(<<c::utf8, rest::binary>>, n) when ?0 <= c and c <= ?9 and n >= 0 do
    do_integer(rest, (n * 10) + (c - ?0))
  end

  defp do_integer(<<c::utf8, rest::binary>>, n) when ?0 <= c and c <= ?9 and n < 0 do
    do_integer(rest, (n * 10) - (c - ?0))
  end

  defp do_integer(rest, n) do
    {n, rest}
  end

  @doc ~S"""
  iex> import Parser
  iex> skip(char("f")) |> char("o") |> parse("foobar")
  {["o"], "obar"}
  iex> skip(char("x")) |> char("f") |> parse("foobar")
  {["f"], "oobar"}
  """
  def skip(parser \\ null(), parser2) do
    build_parser(parser, fn(input) ->
      case parser2.(input) do
        {_result, rest} -> {:noresult, rest}
        :nomatch        -> {:noresult, input}
      end
    end)
  end

  @doc ~S"""
  iex> import Parser
  iex> space() |> parse(" foobar")
  {[" "], "foobar"}
  """
  def space(parser \\ null()) do
    build_parser(parser, fn
      (<<" ", rest::binary>>) -> {" ", rest}
      (_input) -> :nomatch
    end)
  end

  @doc ~S"""
  parse if term matches
  iex> import Parser
  iex> word() |> option(skip(space()) |> word()) |> parse("foo bar")
  {["foo", "bar"], ""}
  iex> word() |> option(skip(space()) |> word()) |> parse("foo")
  {["foo", nil], ""}
  """
  def option(parser \\ null(), parser2) do
    build_parser(parser, fn(input) ->
      case parser2.(input) do
        {[result], rest} -> {result, rest}
        :nomatch         -> {nil, input}
      end
    end)
  end

  @doc ~S"""
  match a specific string
  iex> import Parser
  iex> string("foo") |> string("bar") |> parse("foobarbaz")
  {["foo", "bar"], "baz"}
  iex> string("foo") |> string("bar") |> parse("foobZrbaz")
  :nomatch
  """
  def string(parser \\ null(), s) do
    size = byte_size(s)
    build_parser(parser, fn
      (<<^s::bytes-size(size), rest::binary>>) -> {s, rest}
      (_rest) -> :nomatch
    end)
  end

  @doc ~S"""
  match parser and ignore optional space at either side
  iex> import Parser
  iex> trim(string("foo")) |> parse("   foo   bar")
  {["foo"], "bar"}
  iex> trim(string("foo")) |> parse("foo   bar")
  {["foo"], "bar"}
  iex> trim(string("foo")) |> parse("foobar")
  {["foo"], "bar"}
  """
  def trim(parser \\ null(), parser2) do
    build_parser(parser, fn(input) ->
      with {[], rest}       <- skip(many(space())).(input),
           {[result], rest} <- parser2.(rest),
           {[], rest}       <- skip(many(space())).(rest),
        do: {result, rest}
    end)
  end

  @doc ~S"""
  match parser separated by given parser
  iex> import Parser
  iex> sep_by(word(), char(",")) |> parse("foo,bar,baz cheese")
  {[["foo", "bar", "baz"]], " cheese"}
  iex> sep_by(word(), char(",")) |> parse("foo,bar baz cheese")
  {[["foo", "bar"]], " baz cheese"}
  """
  def sep_by(parser \\ null(), parser2, parser_sep, options \\ []) do
    build_parser(parser, fn(input) ->
      case (many(parser2 |> skip(parser_sep))).(input)  do
        {[result], rest} -> {result, rest}
        :nomatch         -> :nomatch
      end
    end)
  end

  @doc ~S"""
  match newline
  iex> import Parser
  iex> word() |> newline() |> word() |> parse("foo\nbar")
  {["foo", "\n", "bar"], ""}
  """
  def newline(parser \\ null()) do
    build_parser(parser, fn(input) ->
      case char("\n").(input) do
        {["\n"], rest} -> {"\n", rest}
        :nomatch -> :nomatch
      end
    end)
  end
end
