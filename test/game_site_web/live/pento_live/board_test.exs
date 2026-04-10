defmodule GameSiteWeb.PentoLive.BoardTest do
  use ExUnit.Case, async: true

  alias GameSite
  alias GameSiteWeb.PentoLive.Board, as: BoardComponent
  alias GameSite.Pento.Board, as: PentoBoard

  defp socket_with_puzzle(puzzle) do
    %Phoenix.LiveView.Socket{}
    |> BoardComponent.assign_params("board-1", puzzle)
    |> BoardComponent.assign_board()
    |> BoardComponent.assign_shapes()
  end

  defp puzzle_string do
    PentoBoard.puzzles()
    |> hd()
    |> to_string()
  end

  describe "assign_params/3" do
    test "assigns id and puzzle" do
      socket =
        %Phoenix.LiveView.Socket{}
        |> BoardComponent.assign_params("board-1", "easy")

      assert socket.assigns.id == "board-1"
      assert socket.assigns.puzzle == "easy"
    end
  end

  describe "assign_board/1" do
    test "creates a board from the puzzle assign" do
      puzzle = puzzle_string()

      socket =
        %Phoenix.LiveView.Socket{}
        |> BoardComponent.assign_params("board-1", puzzle)
        |> BoardComponent.assign_board()

      assert socket.assigns.board == GameSite.Game.new(String.to_existing_atom(puzzle))
    end
  end

  describe "assign_shapes/1" do
    test "assigns shapes derived from the board" do
      puzzle = puzzle_string()

      socket =
        %Phoenix.LiveView.Socket{}
        |> BoardComponent.assign_params("board-1", puzzle)
        |> BoardComponent.assign_board()
        |> BoardComponent.assign_shapes()

      assert socket.assigns.shapes == GameSite.Game.to_shapes(socket.assigns.board)
      assert is_list(socket.assigns.shapes)
    end
  end

  describe "update/2" do
    test "assigns params, board, and shapes" do
      puzzle = puzzle_string()

      assert {:ok, socket} =
               BoardComponent.update(%{puzzle: puzzle, id: "board-1"}, %Phoenix.LiveView.Socket{})

      assert socket.assigns.id == "board-1"
      assert socket.assigns.puzzle == puzzle
      assert socket.assigns.board == GameSite.Game.new(String.to_existing_atom(puzzle))
      assert socket.assigns.shapes == GameSite.Game.to_shapes(socket.assigns.board)
    end
  end

  describe "all_pieces_placed?/1" do
    test "returns true when completed pentos matches palette length" do
      board = %{
        completed_pentos: [%{name: :a}, %{name: :b}, %{name: :c}],
        palette: [:a, :b, :c]
      }

      assert BoardComponent.all_pieces_placed?(board)
    end

    test "returns false when completed pentos is shorter than palette" do
      board = %{
        completed_pentos: [%{name: :a}, %{name: :b}],
        palette: [:a, :b, :c]
      }

      refute BoardComponent.all_pieces_placed?(board)
    end
  end

  describe "do_key/2" do
    test "returns socket unchanged for unknown key" do
      socket = socket_with_puzzle(puzzle_string())

      assert BoardComponent.do_key(socket, "unknown-key") == socket
    end

    test "escape clears the selected piece" do
      socket = socket_with_puzzle(puzzle_string())

      expected =
        socket
        |> update_in(
          [Access.key!(:assigns), Access.key!(:board)],
          &GameSite.Game.pick(&1, :clear)
        )

      result = BoardComponent.do_key(socket, "Escape")

      assert result.assigns.board == expected.assigns.board
    end
  end

  describe "handle_event/3 key aliases" do
    test "up delegates to ArrowUp" do
      socket = socket_with_puzzle(puzzle_string())

      assert BoardComponent.handle_event("up", %{}, socket) ==
               BoardComponent.handle_event("key", %{"key" => "ArrowUp"}, socket)
    end

    test "down delegates to ArrowDown" do
      socket = socket_with_puzzle(puzzle_string())

      assert BoardComponent.handle_event("down", %{}, socket) ==
               BoardComponent.handle_event("key", %{"key" => "ArrowDown"}, socket)
    end

    test "left delegates to ArrowLeft" do
      socket = socket_with_puzzle(puzzle_string())

      assert BoardComponent.handle_event("left", %{}, socket) ==
               BoardComponent.handle_event("key", %{"key" => "ArrowLeft"}, socket)
    end

    test "right delegates to ArrowRight" do
      socket = socket_with_puzzle(puzzle_string())

      assert BoardComponent.handle_event("right", %{}, socket) ==
               BoardComponent.handle_event("key", %{"key" => "ArrowRight"}, socket)
    end

    test "rotate delegates to Shift" do
      socket = socket_with_puzzle(puzzle_string())

      assert BoardComponent.handle_event("rotate", %{}, socket) ==
               BoardComponent.handle_event("key", %{"key" => "Shift"}, socket)
    end

    test "flip delegates to Enter" do
      socket = socket_with_puzzle(puzzle_string())

      assert BoardComponent.handle_event("flip", %{}, socket) ==
               BoardComponent.handle_event("key", %{"key" => "Enter"}, socket)
    end

    test "drop delegates to space" do
      socket = socket_with_puzzle(puzzle_string())

      assert BoardComponent.handle_event("drop", %{}, socket) ==
               BoardComponent.handle_event("key", %{"key" => " "}, socket)
    end
  end
end
