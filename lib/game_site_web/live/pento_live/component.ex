defmodule GameSiteWeb.PentoLive.Component do
  use Phoenix.Component
  alias GameSite.Pento.{Pentomino}
  import GameSiteWeb.PentoLive.Colors
  @width 10

  attr(:x, :integer, required: true)
  attr(:y, :integer, required: true)
  attr(:fill, :string)
  attr(:name, :string)
  attr(:"phx-click", :string)
  attr(:"phx-value", :string)
  attr(:"phx-target", :any)

  def point(assigns) do
    ~H"""
    <use
      xlink:href="#pento-point"
      x={convert(@x)}
      y={convert(@y)}
      fill={@fill}
      phx-click="pick"
      phx-value-name={@name}
      phx-target="#board-component"
    />
    """
  end

  defp convert(i) do
    (i - 1) * @width + 2 * @width
  end

  attr(:view_box, :string)
  slot(:inner_block, required: true)

  def canvas(assigns) do
    ~H"""
    <svg viewBox={@view_box}>
      <defs>
        <rect id="pento-point" width="10" height="10" />
      </defs>
      {render_slot(@inner_block)}
    </svg>
    """
  end

  attr(:points, :list, required: true)
  attr(:name, :string, required: true)
  attr(:fill, :string, required: true)

  def shape(assigns) do
    ~H"""
    <%= for {x, y} <- @points do %>
      <.point x={x} y={y} fill={@fill} name={@name} />
    <% end %>
    """
  end

  attr(:shape_names, :list, required: true)
  attr(:completed_shape_names, :list, default: [])

  def palette(assigns) do
    ~H"""
    <div id="pento-palette">
      <svg viewBox="0 0 500 125">
        <defs>
          <rect id="palette-point" width="10" height="10" />
        </defs>
        <%= for shape <- palette_shapes(@shape_names) do %>
          <.palette_shape
            points={shape.points}
            fill={color(shape.color, false, shape.name in @completed_shape_names)}
            name={shape.name}
          />
        <% end %>
      </svg>
    </div>
    """
  end

  attr(:points, :list, required: true)
  attr(:name, :string, required: true)
  attr(:fill, :string, required: true)

  def palette_shape(assigns) do
    ~H"""
    <%= for {x, y} <- @points do %>
      <.palette_point x={x} y={y} fill={@fill} name={@name} />
    <% end %>
    """
  end

  attr(:x, :integer, required: true)
  attr(:y, :integer, required: true)
  attr(:fill, :string, required: true)
  attr(:name, :string, required: true)

  def palette_point(assigns) do
    ~H"""
    <use
      xlink:href="#palette-point"
      x={convert(@x)}
      y={convert(@y)}
      fill={@fill}
      phx-click="pick"
      phx-value-name={@name}
      phx-target="#board-component"
    />
    """
  end

  defp palette_shapes(names) do
    names
    |> Enum.with_index()
    |> Enum.map(&place_pento/1)
  end

  defp place_pento({name, i}) do
    Pentomino.new(name: name, location: location(i))
    |> Pentomino.to_shape()
  end

  defp location(i) do
    x = rem(i, 6) * 4 + 3
    y = div(i, 6) * 5 + 3
    {x, y}
  end

  attr(:viewBox, :string)
  slot(:inner_block, required: true)

  def control_panel(assigns) do
    ~H"""
    <svg viewBox={@viewBox}>
      <defs>
        <polygon id="triangle" points="6.25 1.875, 12.5 12.5, 0 12.5" />

        <path
          id="rotate_symbol"
          d="M20 8 A10 10 0 1 0 20 16"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
        />
        <polygon id="rotate_arrow" points="22,18 22,11 17,15" fill="currentColor" />

        <polygon id="flip_left" points="6,12 10,8 10,16" fill="currentColor" />
        <polygon id="flip_right" points="18,12 14,8 14,16" fill="currentColor" />
        <line id="flip_axis" x1="12" y1="4" x2="12" y2="20" stroke="currentColor" stroke-width="2" />

        <line id="drop_axis" x1="22" y1="8" x2="6" y2="8" stroke="currentColor" stroke-width="2" />
        <polygon id="drop_arrow" points="20,12 8,12 14,18" fill="currentColor" />
      </defs>
      {render_slot(@inner_block)}
    </svg>
    """
  end

  attr(:x, :integer, required: true)
  attr(:y, :integer, required: true)
  attr(:rotate, :integer, required: true)
  attr(:fill, :string, required: true)
  attr(:on_click, :string, required: false)

  def triangle(assigns) do
    ~H"""
    <use
      x={@x}
      y={@y}
      transform={"rotate(#{@rotate} #{(@x + 6.25)} #{(@y + 8.958)})"}
      href="#triangle"
      fill={@fill}
      phx-click={@on_click}
      phx-target="#board-component"
      style="cursor: pointer"
    />
    """
  end

  attr(:x, :integer, required: true)
  attr(:y, :integer, required: true)
  attr(:size, :integer, default: 24)
  attr(:fill, :string, required: true)
  attr(:on_click, :string, required: false)

  def drop_symbol(assigns) do
    ~H"""
    <g
      transform={"translate(#{@x}, #{@y}) scale(#{@size / 24})"}
      style={"color: #{@fill}"}
      phx-click={@on_click}
      phx-target="#board-component"
    >
      <use href="#drop_axis" style="cursor: pointer" />
      <use href="#drop_arrow" style="cursor: pointer" />
    </g>
    """
  end

  attr(:x, :integer, required: true)
  attr(:y, :integer, required: true)
  attr(:size, :integer, default: 24)
  attr(:fill, :string, required: true)
  attr(:on_click, :string, required: false)

  def rotate_symbol(assigns) do
    ~H"""
    <g
      transform={"translate(#{@x}, #{@y}) scale(#{@size / 24})"}
      style={"color: #{@fill}"}
      phx-click={@on_click}
      phx-target="#board-component"
    >
      <use href="#rotate_symbol" style="cursor: pointer" />
      <use href="#rotate_arrow" style="cursor: pointer" />
    </g>
    """
  end

  attr(:x, :integer, required: true)
  attr(:y, :integer, required: true)
  attr(:size, :integer, default: 24)
  attr(:fill, :string, required: true)
  attr(:on_click, :string, required: false)

  def flip_symbol(assigns) do
    ~H"""
    <g
      transform={"translate(#{@x}, #{@y}) scale(#{@size / 24})"}
      style={"color: #{@fill}"}
      phx-click={@on_click}
      style="cursor: pointer"
      phx-target="#board-component"
    >
      <use href="#flip_left" style="cursor: pointer" />
      <use href="#flip_right" style="cursor: pointer" />
      <use href="#flip_axis" style="cursor: pointer" />
    </g>
    """
  end

  attr(:score, :integer, required: true)
  attr(:moves, :integer, required: true)

  def score_board(assigns) do
    ~H"""
    <div class="flex justify-between items-center px-4 py-2
                bg-gray-100 dark:bg-gray-800
                rounded-lg shadow-sm">
      <div>
        <div class="text-xs uppercase tracking-wide
                    text-gray-500 dark:text-gray-400">
          Score
        </div>

        <div class="text-2xl font-semibold tabular-nums
                    text-gray-900 dark:text-gray-100">
          {@score}
        </div>
      </div>

      <div class="text-right">
        <div class="text-xs uppercase tracking-wide
                    text-gray-500 dark:text-gray-400">
          Moves
        </div>

        <div class="text-lg tabular-nums
                    text-gray-900 dark:text-gray-100">
          {@moves}
        </div>
      </div>
    </div>
    """
  end
end
