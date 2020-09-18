defmodule TextGraph2d do
  @moduledoc """
  Documentation for TextGraph2d.
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
          left:   all_tokens() -- [:end_identifier],
          right:  all_tokens() -- [:end_identifier, :vertical_edge, :horizontal_edge, :intersection_edge, :grapheme],
        }

      :grapheme ->
        %{
          up:     all_tokens(),
          down:   all_tokens(),
          left:   all_tokens() -- [:start_identifier, :vertical_edge, :horizontal_edge, :intersection_edge],
          right:  all_tokens() -- [:end_identifier,   :vertical_edge, :horizontal_edge, :intersection_edge],
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
