defmodule GameSiteWeb.PentoLive.PickerTest do
  use GameSiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias GameSite.Pento.Board
  alias GameSiteWeb.PentoLive.Picker

  describe "assign_boards/1" do
    test "assigns boards for every puzzle" do
      socket = %Phoenix.LiveView.Socket{}
      socket = Picker.assign_boards(socket)

      assert %{boards: boards} = socket.assigns
      assert is_list(boards)
      assert length(boards) == length(Board.puzzles())

      assert Enum.all?(boards, fn {puzzle, board} ->
               puzzle in Board.puzzles() and match?(%Board{}, board)
             end)
    end
  end

  describe "mount/3" do
    test "assigns boards on mount" do
      socket = %Phoenix.LiveView.Socket{}

      assert {:ok, mounted_socket} = Picker.mount(%{}, %{}, socket)
      assert %{boards: boards} = mounted_socket.assigns
      assert is_list(boards)
      assert length(boards) == length(Board.puzzles())
    end
  end

  describe "render/1" do
    test "renders heading and one row per puzzle" do
      boards =
        Board.puzzles()
        |> Enum.map(&{&1, Board.new(&1)})

      html =
        render_component(&Picker.render/1,
          boards: boards
        )

      assert html =~ "Choose a Puzzle"

      Enum.each(Board.puzzles(), fn puzzle ->
        assert html =~ "#{puzzle |> to_string() |> String.capitalize()} Puzzle"
      end)
    end
  end

  describe "row/1" do
    test "renders puzzle label and navigation link" do
      puzzle = hd(Board.puzzles())
      board = Board.new(puzzle)

      html =
        render_component(&Picker.row/1,
          board: board,
          puzzle: puzzle
        )

      assert html =~ "Pieces"
      assert html =~ "#{puzzle |> to_string() |> String.capitalize()} Puzzle"
      assert html =~ ~p"/pento/#{puzzle}"
    end
  end

  describe "board/1" do
    test "renders svg board content" do
      puzzle = hd(Board.puzzles())
      board = Board.new(puzzle)

      html =
        render_component(&Picker.board/1,
          board: board
        )

      assert html =~ "svg"
      assert html =~ "board"
      assert html =~ "viewBox"
    end
  end
end
