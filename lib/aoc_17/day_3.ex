defmodule Aoc17.Day3 do
  defmodule State do
    defstruct [
      n: 1,
      pos: {0,0},
      heading: :right,
      width: 1,
      progress: 1,
      side: 1,
      data: %{ {0,0} => 1}
    ]

    def step(%State{
      n: n,
      pos: pos,
      width: width,
      progress: progress,
      heading: heading,
      data: data
    } = state)
    when progress < width do
      new_pos = move(pos, heading)
      %State{state|
        n: n+1,
        pos: new_pos,
        progress: progress + 1,
        data: Map.put(data, new_pos, adjacent_sum(new_pos, data))
      }
    end

    def step(%State{
      n: n,
      pos: pos,
      width: width,
      progress: progress,
      heading: heading,
      side: side,
      data: data
    } = state)
    when progress == width do
      new_heading = rotate(heading)
      new_pos = move(pos, heading)
      %State{state|
        n: n + 1,
        pos: new_pos,
        progress: 1,
        width: grow_width(width, side),
        side: side + 1,
        heading: new_heading,
        data: Map.put(data, new_pos, adjacent_sum(new_pos, data))
      }
    end

    def distance(%State{pos: {x, y}}), do: abs(x) + abs(y)

    def data(%State{pos: pos, data: data}), do: data[pos]

    defp move({x,y}, :right), do: {x+1,  y}
    defp move({x,y}, :up)   , do: {x,    y-1}
    defp move({x,y}, :left) , do: {x-1,  y}
    defp move({x,y}, :down) , do: {x,    y+1}

    defp rotate(:right), do: :up
    defp rotate(:up), do: :left
    defp rotate(:left), do: :down
    defp rotate(:down), do: :right

    defp grow_width(width, side) when rem(side, 2) == 0, do: width + 1
    defp grow_width(width, side) when rem(side, 2) != 0, do: width

    defp adjacent_sum({x,y}, data) do
      [
        {x-1, y-1},
        {x,   y-1},
        {x+1, y-1},
        {x-1, y},
        {x, y},
        {x+1, y},
        {x-1, y+1},
        {x,   y+1},
        {x+1, y+1}
      ]
      |> Enum.reduce(0, fn(pos, sum) -> (data[pos] || 0) + sum end)
    end
  end

  @doc """
    iex> Aoc17.Day3.part1(1)
    0

    iex> Aoc17.Day3.part1(12)
    3

    iex> Aoc17.Day3.part1(23)
    2

    iex> Aoc17.Day3.part1(1024)
    31
  """
  def part1(input) do
    at(input)
    |> State.distance
  end

  @doc """
    iex> Aoc17.Day3.part2(1)
    2

    iex> Aoc17.Day3.part2(2)
    4

    iex> Aoc17.Day3.part2(3)
    4

    iex> Aoc17.Day3.part2(4)
    5

    iex> Aoc17.Day3.part2(5)
    10
  """
  def part2(input) do
    stream()
    |> Enum.find(fn(state) -> State.data(state) > input end)
    |> State.data
  end

  defp stream do
    Stream.unfold(%State{}, fn(state) ->
      {state, State.step(state)}
    end)
  end

  def at(input) do
    stream()
    |> Enum.at(input - 1)
  end

end
