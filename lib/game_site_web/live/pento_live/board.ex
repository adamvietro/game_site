defmodule GameSiteWeb.PentoLive.Board do
  use GameSiteWeb, :live_component
  import GameSiteWeb.PentoLive.Component
  alias GameSite.Game
  import GameSiteWeb.PentoLive.{Colors, Component}

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} phx-window-keydown="key" phx-target={@myself}>
      <.score_board score={score(@board)} moves={@board.moves} />
      <.canvas view_box="0 0 200 100">
        <%= for shape <- @shapes do %>
          <.shape
            points={shape.points}
            fill={color(shape.color, Game.active?(@board, shape.name), false)}
            name={shape.name}
          />
        <% end %>
      </.canvas>
      <hr />
      <.palette
        shape_names={@board.palette}
        completed_shape_names={Enum.map(@board.completed_pentos, & &1.name)}
      />
      <.control_panel viewBox="0 0 200 40">
        <.triangle x={20} y={0} rotate={0} fill={color(:orange, true, true)} on_click="up" />
        <.triangle x={30} y={10} rotate={90} fill={color(:orange, true, false)} on_click="right" />
        <.triangle x={20} y={20} rotate={180} fill={color(:orange, true, false)} on_click="down" />
        <.triangle x={10} y={10} rotate={270} fill={color(:orange, true, false)} on_click="left" />

        <.rotate_symbol x={50} y={5} size={30} fill={color(:orange, true, false)} on_click="rotate" />
        <.flip_symbol x={80} y={5} size={30} fill={color(:orange, true, false)} on_click="flip" />
        <.drop_symbol x={105} y={5} size={30} fill={color(:orange, true, false)} on_click="drop" />
      </.control_panel>
      <hr />
    </div>
    """
  end

  @impl true
  def update(%{puzzle: puzzle, id: id}, socket) do
    {:ok,
     socket
     |> assign_params(id, puzzle)
     |> assign_board()
     |> assign_shapes()}
  end

  @impl true
  def handle_event("pick", %{"name" => name}, socket) do
    {:noreply, socket |> pick(name) |> assign_shapes}
  end

  @impl true
  def handle_event("key", %{"key" => key}, socket) do
    {:noreply, socket |> do_key(key) |> assign_shapes}
  end

  @impl true
  def handle_event("up", _, socket), do: handle_event("key", %{"key" => "ArrowUp"}, socket)
  @impl true
  def handle_event("down", _, socket), do: handle_event("key", %{"key" => "ArrowDown"}, socket)
  @impl true
  def handle_event("left", _, socket), do: handle_event("key", %{"key" => "ArrowLeft"}, socket)
  @impl true
  def handle_event("right", _, socket), do: handle_event("key", %{"key" => "ArrowRight"}, socket)
  @impl true
  def handle_event("rotate", _, socket), do: handle_event("key", %{"key" => "Shift"}, socket)
  @impl true
  def handle_event("flip", _, socket), do: handle_event("key", %{"key" => "Enter"}, socket)
  @impl true
  def handle_event("drop", _, socket), do: handle_event("key", %{"key" => " "}, socket)

  def do_key(socket, key) do
    case key do
      " " ->
        drop(socket)

      "ArrowLeft" ->
        move(socket, :left)

      "ArrowRight" ->
        move(socket, :right)

      "ArrowUp" ->
        move(socket, :up)

      "ArrowDown" ->
        move(socket, :down)

      "Shift" ->
        move(socket, :rotate)

      "Enter" ->
        move(socket, :flip)

      "Space" ->
        drop(socket)

      "Escape" ->
        pick(socket, :clear)

      _ ->
        socket
    end
  end

  def move(socket, move) do
    case Game.maybe_move(socket.assigns.board, move) do
      {:error, message} ->
        send(self(), {:flash, message})
        socket

      {:ok, board} ->
        socket |> assign(board: board) |> assign_shapes
    end
  end

  defp drop(socket) do
    case Game.maybe_drop(socket.assigns.board) do
      {:error, message} ->
        send(self(), {:flash, message})
        socket

      {:ok, board} ->
        if all_pieces_placed?(board) do
          send(self(), :board_complete)
          socket
        else
          socket
        end
        |> assign(board: board)
        |> assign_shapes
    end
  end

  defp pick(socket, :clear) do
    %{socket | assigns: %{socket.assigns | board: Game.pick(socket.assigns.board, :clear)}}
  end

  defp pick(socket, name) do
    shape_name = String.to_existing_atom(name)
    update(socket, :board, &Game.pick(&1, shape_name))
  end

  defp score(board) do
    500 * length(board.completed_pentos) - board.moves
  end

  def all_pieces_placed?(board) do
    length(board.completed_pentos) == length(board.palette)
  end

  def assign_params(socket, id, puzzle) do
    assign(socket, id: id, puzzle: puzzle)
  end

  def assign_board(%{assigns: %{puzzle: puzzle}} = socket) do
    board =
      puzzle
      |> String.to_existing_atom()
      |> Game.new()

    assign(socket, board: board)
  end

  def assign_shapes(%{assigns: %{board: board}} = socket) do
    shapes = Game.to_shapes(board)
    assign(socket, shapes: shapes)
  end
end
