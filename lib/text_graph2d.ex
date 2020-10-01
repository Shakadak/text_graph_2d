defmodule TextGraph2d do
  @moduledoc """
  Documentation for `TextGraph2d`.
  """

  def parse(bin) do
    lines = Enum.with_index(String.split(bin, "\n", trim: true))
    grid = Map.new(Enum.flat_map(lines, fn {line, y} ->
      graphemes = Enum.with_index(String.graphemes(line))
      Enum.map(graphemes, fn {g, x} -> {{x, y}, g} end)
    end))
    grid
  end

  def tokenize(grapheme) do
    case grapheme do
      " " -> :empty
      "|" -> :vertical_edge
      "-" -> :horizontal_edge
      "+" -> :intersection_edge
      "(" -> :start_identifier
      ")" -> :end_identifier
      _   -> :grapheme
    end
  end

  def tokenize_grid(grid) do
    Map.new(grid, fn {xy, g} -> {xy, {g, tokenize(g)}} end)
  end

  def validate(tokenized_grid) do
    Enum.map(tokenized_grid, fn {xy, {g, _}} ->
      xs =
        [
          validate(tokenized_grid, xy, :up),
          validate(tokenized_grid, xy, :down),
          validate(tokenized_grid, xy, :left),
          validate(tokenized_grid, xy, :right),
        ]
        |> Enum.filter(fn x -> match?({:error, _}, x) end)
        |> Enum.map(fn {:error, {:unexpected_neighbor, n}} -> n end)

      case xs do
        [] -> {xy, {g, :ok}}
        xs -> {xy, {g, {:unexpected_neighbors, xs}}}
      end
    end)
    |> Enum.filter(fn x -> match?({_, {_, {:unexpected_neighbors, _}}}, x) end)
    |> Map.new()
    |> case do
      x when map_size(x) == 0 -> :ok
      x when map_size(x) > 0 -> {:error, x}
    end
  end

  def validate(tokenized_grid, xy, direction) do
    {_, token} = Map.fetch!(tokenized_grid, xy)
    neighbor_xy = neighbor_xy(xy, direction)
    {_, neighbor_token} = neighbor = Map.get(tokenized_grid, neighbor_xy, {" ", :empty})
    case neighbor_token in Map.fetch!(expected_neighbors(token), direction) do
      true -> :ok
      false -> {:error, {:unexpected_neighbor, {neighbor_xy, neighbor}}}
    end
  end

  def neighbor_xy({x, y}, :up), do: {x, y - 1}
  def neighbor_xy({x, y}, :down), do: {x, y + 1}
  def neighbor_xy({x, y}, :left), do: {x - 1, y}
  def neighbor_xy({x, y}, :right), do: {x + 1, y}

  def expected_neighbors(token) do
    case token do
      :empty ->
        %{
          up:     all_tokens() -- [:vertical_edge],
          down:   all_tokens() -- [:vertical_edge],
          left:   all_tokens() -- [:horizontal_edge],
          right:  all_tokens() -- [:horizontal_edge],
        }

      :vertical_edge ->
        %{
          up:     all_tokens() -- [:horizontal_edge],
          down:   all_tokens() -- [:horizontal_edge],
          left:   all_tokens() -- [:horizontal_edge, :start_identifier, :grapheme],
          right:  all_tokens() -- [:horizontal_edge, :end_identifier, :grapheme],
        }

      :horizontal_edge ->
        %{
          up:     all_tokens() -- [:vertical_edge],
          down:   all_tokens() -- [:vertical_edge],
          left:   all_tokens() -- [:vertical_edge, :start_identifier, :grapheme],
          right:  all_tokens() -- [:vertical_edge, :end_identifier, :grapheme],
        }

      :intersection_edge ->
        %{
          up:     all_tokens(),
          down:   all_tokens(),
          left:   all_tokens() -- [:start_identifier, :grapheme],
          right:  all_tokens() -- [:end_identifier, :grapheme],
        }

      :start_identifier ->
        %{
          up:     all_tokens(),
          down:   all_tokens(),
          left:   all_tokens() -- [:start_identifier, :grapheme],
          right:  all_tokens() -- [:start_identifier, :vertical_edge, :horizontal_edge, :intersection_edge],
        }

      :end_identifier ->
        %{
          up:     all_tokens(),
          down:   all_tokens(),
          left:   all_tokens() -- [:end_identifier, :vertical_edge, :horizontal_edge, :intersection_edge],
          right:  all_tokens() -- [:end_identifier, :grapheme],
        }

      :grapheme ->
        %{
          up:     all_tokens(),
          down:   all_tokens(),
          left:   all_tokens() -- [:end_identifier, :vertical_edge, :horizontal_edge, :intersection_edge],
          right:  all_tokens() -- [:start_identifier,   :vertical_edge, :horizontal_edge, :intersection_edge],
        }
    end
  end

  def all_tokens do
    [
      :empty,
      :vertical_edge,
      :horizontal_edge,
      :intersection_edge,
      :start_identifier,
      :end_identifier,
      :grapheme,
    ]
  end
end
