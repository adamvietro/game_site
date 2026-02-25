defmodule GameSite.Pento.Pentomino do
  alias GameSite.Pento.Shape
  alias GameSite.Pento.Point

  @names [:i, :l, :y, :n, :p, :w, :u, :v, :s, :f, :x, :t]
  @default_location {8, 8}
  defstruct name: @names,
            rotation: 0,
            reflected: false,
            location: @default_location

  def new(fields \\ []), do: __struct__(fields)

  def rotate(%{rotation: degrees} = p, clockwise \\ :clockwise) do
    degrees = if clockwise == :counterclockwise, do: 360 - 90 + degrees, else: degrees + 90
    %{p | rotation: rem(degrees, 360)}
  end

  def flip(%{reflected: reflection} = p) do
    %{p | reflected: not reflection}
  end

  def up(p) do
    %{p | location: Point.move(p.location, {0, -1})}
  end

  def down(p) do
    %{p | location: Point.move(p.location, {0, 1})}
  end

  def left(p) do
    %{p | location: Point.move(p.location, {-1, 0})}
  end

  def right(p) do
    %{p | location: Point.move(p.location, {1, 0})}
  end

  def overlapping?(pento1, pento2) do
    {p1, p2} = {to_shape(pento1).points, to_shape(pento2).points}
    Enum.count(p1 -- p2) != 5
  end

  def to_shape(pento) do
    Shape.new(pento.name, pento.rotation, pento.reflected, pento.location)
  end
end
