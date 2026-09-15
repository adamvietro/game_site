defmodule GameSiteWeb.PentoLive.Picker do
  use GameSiteWeb, :live_view
  alias GameSite.Pento.Board
  import GameSiteWeb.PentoLive.{Colors, Component}

  def mount(_params, _session, socket) do
    {:ok, assign_boards(socket)}
  end

  def assign_boards(socket) do
    assign(
      socket,
      :boards,
      Board.puzzles()
      |> Enum.map(&{&1, Board.new(&1)})
    )
  end

  def render(assigns) do
    ~H"""
    <h1 class="font-heavy text-4xl text-center mb-6">
      Choose a Puzzle
    </h1>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
      <%= for {puzzle, board} <- @boards do %>
        <.row board={board} puzzle={puzzle} />
      <% end %>
    </div>
    """
  end

  def row(assigns) do
    ~H"""
    <.link navigate={~p"/pento/#{@puzzle}"}>
      <div class="grid grid-cols-2 gap-4 p-4
            divide-x divide-slate-300
            border-2 border-slate-300
            rounded-xl bg-gray-100
            shadow-sm hover:shadow-lg
            hover:bg-gray-200
            transform hover:-translate-y-0.5
            transition-all duration-200 cursor-pointer dark:bg-gray-800 dark:hover:bg-gray-700">
        <div class="pr-4 space-y-2">
          <h3 class="text-xl sm:text-2xl">Pieces</h3>
          <.palette shape_names={@board.palette} />
        </div>

        <div class="pl-4 space-y-2">
          <h3 class="text-xl sm:text-2xl">
            {@puzzle |> to_string() |> String.capitalize()} Puzzle
          </h3>
          <.board board={@board} />
        </div>
      </div>
    </.link>
    """
  end

  attr(:board, :any, required: true)

  def board(assigns) do
    ~H"""
    <div>
      <.canvas view_box={"0 0 400 #{height(@board) * 10 + 25}"}>
        <.shape points={Board.to_shape(@board).points} fill={color(:purple)} name="board" />
      </.canvas>
    </div>
    """
  end

  defp height(board) do
    board.points
    |> Enum.map(fn {_, y} -> y end)
    |> Enum.max()
  end
end
