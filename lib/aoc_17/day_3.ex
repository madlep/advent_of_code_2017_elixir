defmodule Aoc17.Day3 do
  defmodule State do
    defstruct [
      n: 1,
      pos: {0,0},
      heading: :right,
      width: 1,
      progress: 1,
      side: 1
    ]

    def step(%State{
      n: n,
      pos: pos,
      width: width,
      progress: progress,
      heading: heading
    } = state)
    when progress < width do
      %State{state|
        n: n+1,
        pos: move(pos, heading),
        progress: progress + 1
      }
    end

    def step(%State{
      n: n,
      pos: pos,
      width: width,
      progress: progress,
      heading: heading,
      side: side
    } = state)
    when progress == width do
      new_heading = rotate(heading)
      %State{state|
        n: n + 1,
        pos: move(pos, heading),
        progress: 1,
        width: grow_width(width, side),
        side: side + 1,
        heading: new_heading
      }
    end

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

    def distance(%State{pos: {x, y}}), do: abs(x) + abs(y)
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
    Stream.unfold(%State{}, fn(state) ->
      {state, State.step(state)}
    end)
    |> Enum.at(input - 1)
    |> State.distance
  end

end
