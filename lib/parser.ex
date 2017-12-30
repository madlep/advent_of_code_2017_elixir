defmodule Parser do
  defmodule Result do
    defstruct value: :nomatch, rest: ""

    def reverse(result = %Result{value: value}) do
      %Result{result|value: deep_reverse(value)}
    end

    def reverse(not_result), do: not_result

    defp deep_reverse(value) when is_list(value) do
      value
      |> Enum.reverse
      |> Enum.map(&deep_reverse/1)
    end

    defp deep_reverse(value) when not is_list(value), do: value
  end

  defmodule NoResult do
    defstruct rest: ""
  end

  defmodule NoMatch do
    defstruct []
  end

  def parse(parser, input) do
    input
    |> parser.()
    |> Result.reverse
  end

  def null(), do: fn(input) -> %Result{value: [], rest: input} end

  defp build_parser(parser, parser_fn) do
    fn(input) ->
      case parser.(input) do
        %Result{value: prior_value, rest: new_input} ->
          case parser_fn.(new_input) do
            %NoResult{rest: rest} ->
              %Result{value: prior_value, rest: rest}
            %Result{value: value, rest: rest} ->
              %Result{value: [value|prior_value], rest: rest}
            %NoMatch{} ->
              %NoMatch{}
          end
        %NoMatch{} -> %NoMatch{}
      end
    end
  end

  @doc ~S"""
  parse a specified character

  iex> import Parser
  iex> char("f") |> parse("foobar")
  %Parser.Result{value: ["f"], rest: "oobar"}
  iex> char("f") |> char("o") |> parse("foobar")
  %Parser.Result{value: ["f", "o"], rest: "obar"}
  iex> char("X") |> parse("foobar")
  %Parser.NoMatch{}
  """
  def char(parser \\ null(), c) do
    build_parser(parser, fn(input) ->
      case anychar().(input) do
        %Result{value: [^c], rest: rest} -> %Result{value: c, rest: rest}
        %Result{} -> %NoMatch{}
        %NoMatch{} -> %NoMatch{}
      end
    end)
  end

  @doc ~S"""
  parse any single alpha character

  iex> import Parser
  iex> anychar() |> parse("foobar")
  %Parser.Result{value: ["f"], rest: "oobar"}
  iex> anychar() |> anychar() |> parse("foobar")
  %Parser.Result{value: ["f", "o"], rest: "obar"}
  iex> anychar() |> parse("@#$%")
  %Parser.Result{value: ["@"], rest: "#$%"}
  iex> anychar() |> parse("")
  %Parser.NoMatch{}
  """
  def anychar(parser \\ null()) do
    build_parser(parser, fn
      (<<c::utf8, rest::binary>>) -> %Result{value: <<c>>, rest: rest}
      (_rest) -> %NoMatch{}
    end)
  end

  @doc ~S"""
  parse an alphabetic character (a-z, A-Z)

  iex> import Parser
  iex> alpha() |> parse("foobar")
  %Parser.Result{value: ["f"], rest: "oobar"}
  iex> alpha() |> alpha() |> parse("foobar")
  %Parser.Result{value: ["f", "o"], rest: "obar"}
  iex> alpha() |> parse("@#$%")
  %Parser.NoMatch{}
  """
  def alpha(parser \\ null()) do
    build_parser(parser, fn(input) ->
      case anychar().(input) do
        %Result{value: [c], rest: rest}
        when ("a" <= c  and c <= "z") or ("A" <= c and c <= "Z") ->
          %Result{value: c, rest: rest}
        %Result{} -> %NoMatch{}
        %NoMatch{} -> %NoMatch{}
      end
    end)
  end

  @doc ~S"""
  match many parsers

  iex> import Parser
  iex> many(alpha()) |> parse("foo bar baz")
  %Parser.Result{value: [["f", "o", "o"]], rest: " bar baz"}
  """
  def many(parser \\ null(), parser2) do
    build_parser(parser, fn(input) ->
      do_many(input, parser2, [])
    end)
  end

  defp do_many(input, parser, result) do
    case parser.(input) do
      %Result{value: [parsed], rest: rest} -> do_many(rest, parser, [parsed|result])
      %NoMatch{}       -> %Result{value: result, rest: input}
    end
  end

  @doc ~S"""
  match a word

  iex> import Parser
  iex> word() |> parse("foo bar baz")
  %Parser.Result{value: ["foo"], rest: " bar baz"}
  iex> word() |> parse("foo+bar")
  %Parser.Result{value: ["foo"], rest: "+bar"}
  iex> word() |> parse("1+2")
  %Parser.NoMatch{}
  """
  def word(parser \\ null()) do
    build_parser(parser, fn(input) ->
      %Result{value: [result], rest: rest} = many(alpha()).(input)
      case result |> Enum.reverse |> Enum.join do
        "" -> %NoMatch{}
        word -> %Result{value: word, rest: rest}
      end
    end)
  end

  @doc ~S"""
  match a parser between two other parsers (e.g. term between brackets etc)

  iex> import Parser
  iex> between(char("("), word(), char(")")) |> parse("(foo)bar")
  %Parser.Result{value: ["foo"], rest: "bar"}
  iex> between(char("("), word(), char(")")) |> parse("(foo]bar")
  %Parser.NoMatch{}
  """
  def between(parser \\ null(), parser_left, parser2, parser_right) do
    build_parser(parser, fn(input) ->
      with %Result{value: [], rest: rest}       <- ignore(parser_left).(input),
           %Result{value: [result], rest: rest} <- parser2.(rest),
           %Result{value: [], rest: rest}       <- ignore(parser_right).(rest),
        do: %Result{value: result, rest: rest}
    end)
  end

  @doc ~S"""
  iex> import Parser
  iex> ignore(char("f")) |> char("o") |> parse("foobar")
  %Parser.Result{value: ["o"], rest: "obar"}
  iex> ignore(char("x")) |> char("o") |> parse("foobar")
  %Parser.NoMatch{}
  """
  def ignore(parser \\ null(), parser2) do
    build_parser(parser, fn(input) ->
      case parser2.(input) do
        %Result{rest: rest} -> %NoResult{rest: rest}
        %NoMatch{} -> %NoMatch{}
      end
    end)
  end

  @doc ~S"""
  parse an integer
  iex> import Parser
  iex> integer() |> parse("123 abc")
  %Parser.Result{value: [123], rest: " abc"}
  iex> integer() |> parse("-123 abc")
  %Parser.Result{value: [-123], rest: " abc"}
  iex> integer() |> parse("a123 abc")
  %Parser.NoMatch{}
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

  defp do_integer(_rest, :unsigned), do: %NoMatch{}

  defp do_integer(<<c::utf8, rest::binary>>, n) when ?0 <= c and c <= ?9 and n >= 0 do
    do_integer(rest, (n * 10) + (c - ?0))
  end

  defp do_integer(<<c::utf8, rest::binary>>, n) when ?0 <= c and c <= ?9 and n < 0 do
    do_integer(rest, (n * 10) - (c - ?0))
  end

  defp do_integer(rest, n) do
    %Result{value: n, rest: rest}
  end

  @doc ~S"""
  iex> import Parser
  iex> skip(char("f")) |> char("o") |> parse("foobar")
  %Parser.Result{value: ["o"], rest: "obar"}
  iex> skip(char("x")) |> char("f") |> parse("foobar")
  %Parser.Result{value: ["f"], rest: "oobar"}
  """
  def skip(parser \\ null(), parser2) do
    build_parser(parser, fn(input) ->
      case parser2.(input) do
        %Result{rest: rest} -> %NoResult{rest: rest}
        %NoMatch{} -> %NoResult{rest: input}
      end
    end)
  end

  @doc ~S"""
  iex> import Parser
  iex> space() |> parse(" foobar")
  %Parser.Result{value: [" "], rest: "foobar"}
  iex> space() |> parse("foobar")
  %Parser.NoMatch{}
  """
  def space(parser \\ null()) do
    build_parser(parser, fn
      (<<" ", rest::binary>>) -> %Result{value: " ", rest: rest}
      (_input) -> %NoMatch{}
    end)
  end

  @doc ~S"""
  parse if term matches
  iex> import Parser
  iex> word() |> option(skip(space()) |> word()) |> parse("foo bar")
  %Parser.Result{value: ["foo", "bar"], rest: ""}
  iex> word() |> option(skip(space()) |> word()) |> parse("foo")
  %Parser.Result{value: ["foo", nil], rest: ""}
  """
  def option(parser \\ null(), parser2) do
    build_parser(parser, fn(input) ->
      case parser2.(input) do
        %Result{value: [result], rest: rest} -> %Result{value: result, rest: rest}
        %NoMatch{}         -> %Result{value: nil, rest: input}
      end
    end)
  end

  @doc ~S"""
  match a specific string
  iex> import Parser
  iex> string("foo") |> string("bar") |> parse("foobarbaz")
  %Parser.Result{value: ["foo", "bar"], rest: "baz"}
  iex> string("foo") |> string("bar") |> parse("foobZrbaz")
  %Parser.NoMatch{}
  """
  def string(parser \\ null(), s) do
    size = byte_size(s)
    build_parser(parser, fn
      (<<^s::bytes-size(size), rest::binary>>) -> %Result{value: s, rest: rest}
      (_rest) -> %NoMatch{}
    end)
  end

  @doc ~S"""
  match parser and ignore optional space at either side
  iex> import Parser
  iex> trim(string("foo")) |> parse("   foo   bar")
  %Parser.Result{value: ["foo"], rest: "bar"}
  iex> trim(string("foo")) |> parse("foo   bar")
  %Parser.Result{value: ["foo"], rest: "bar"}
  iex> trim(string("foo")) |> parse("foobar")
  %Parser.Result{value: ["foo"], rest: "bar"}
  """
  def trim(parser \\ null(), parser2) do
    build_parser(parser, fn(input) ->
      with %Result{value: [], rest: rest}       <- skip(many(space())).(input),
           %Result{value: [result], rest: rest} <- parser2.(rest),
           %Result{value: [], rest: rest}       <- skip(many(space())).(rest),
        do: %Result{value: result, rest: rest}
    end)
  end

  @doc ~S"""
  match parser separated by given parser
  iex> import Parser
  iex> sep_by(word(), char(",")) |> parse("foo,bar,baz cheese")
  %Parser.Result{value: [[["foo"], ["bar"], ["baz"]]], rest: " cheese"}
  iex> sep_by(word(), char(",")) |> parse("foo,bar baz cheese")
  %Parser.Result{value: [[["foo"], ["bar"]]], rest: " baz cheese"}
  iex> sep_by(word(), char(",")) |> parse("foo,bar cheese")
  %Parser.Result{value: [[["foo"], ["bar"]]], rest: " cheese"}
  iex> sep_by(word(), char(",")) |> parse("foo cheese")
  %Parser.Result{value: [[["foo"]]], rest: " cheese"}
  iex> null() |> sep_by(word(), char(","), unlist: true) |> parse("foo,bar,baz cheese")
  %Parser.Result{value: [["foo", "bar", "baz"]], rest: " cheese"}
  """
  def sep_by(parser \\ null(), parser2, parser_sep, options \\ []) do
    build_parser(parser, fn(input) ->
      case parser2.(input) do
        %Result{value: result, rest: rest} ->
          do_sep_by(rest, parser2, parser_sep, [result], options)
        %NoMatch{} ->
          %Result{value: [], rest: input}
      end
    end)
  end

  defp do_sep_by(input, parser, parser_sep, results, options) do
    case ignore(parser_sep).(input) do
      %NoMatch{} ->
        %Result{value: results |> Enum.map(&unlist(&1, options[:unlist])), rest: input}
      %Result{value: [], rest: rest}  ->
        case parser.(rest) do
          %NoMatch{} ->
            %Result{value: results |> Enum.map(&unlist(&1, options[:unlist])), rest: input}
          %Result{value: result, rest: rest} ->
            do_sep_by(rest, parser, parser_sep, [result|results], options)
        end
    end
  end

  defp unlist(v, _) when not is_list(v), do: v
  defp unlist(l, unlist?) when unlist? in [nil, false], do: l
  defp unlist([], true), do: []
  defp unlist([value], true), do: value
  defp unlist([_h|_t]=l, true) do
    raise "can't unlist. Result has more than one element result=#{inspect(l)}"
  end

  @doc ~S"""
  match newline
  iex> import Parser
  iex> word() |> newline() |> word() |> parse("foo\nbar")
  %Parser.Result{value: ["foo", "\n", "bar"], rest: ""}
  iex> word() |> newline() |> word() |> parse("foo bar")
  %Parser.NoMatch{}
  """
  def newline(parser \\ null()) do
    build_parser(parser, fn(input) ->
      case char("\n").(input) do
        %Result{value: ["\n"], rest: rest} -> %Result{value: "\n", rest: rest}
        %NoMatch{} -> %NoMatch{}
      end
    end)
  end
end
