defmodule GameSiteWeb.Live.WordleLive.GameBoardComponentTest do
  use GameSiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias GameSiteWeb.WordleLive.GameBoard

  test "game_board renders labels and board classes" do
    board_state =
      Enum.reduce(0..29, %{}, fn index, acc ->
        Map.put(acc, index, "bg-gray-100")
      end)

    entries = %{
      first: %{l1: "h", l2: "e", l3: "l", l4: "l", l5: "o"},
      second: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."},
      third: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."},
      fourth: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."},
      fifth: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."},
      sixth: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."}
    }

    html =
      render_component(&GameBoard.game_board/1,
        board_state: board_state,
        entries: entries
      )

    assert html =~ "h"
    assert html =~ "e"
    assert html =~ "l"
    assert html =~ "o"
    assert html =~ "bg-gray-100"
  end

  test "keyboard_row renders letters and classes" do
    attr = GameBoard.get_keyboard_row_attr(:top)

    keyboard =
      Enum.into(attr.letters, %{}, fn key ->
        {key, "bg-gray-200"}
      end)

    html =
      render_component(&GameBoard.keyboard_row/1,
        attr: attr,
        keyboard: keyboard
      )

    assert html =~ "q"
    assert html =~ "w"
    assert html =~ "p"
    assert html =~ "phx-click=\"add_letter\""
    assert html =~ "bg-gray-200"
  end

  test "keyboard_delete renders delete button" do
    html = render_component(&GameBoard.keyboard_delete/1, %{})

    assert html =~ "Delete"
    assert html =~ "phx-click=\"delete_letter\""
  end

  test "keyboard renders all rows and delete button" do
    letters = ~w(q w e r t y u i o p a s d f g h j k l z x c v b n m)a

    keyboard =
      Enum.into(letters, %{}, fn key ->
        {key, "bg-gray-200"}
      end)

    html =
      render_component(&GameBoard.keyboard/1,
        keyboard: keyboard
      )

    assert html =~ "q"
    assert html =~ "a"
    assert html =~ "z"
    assert html =~ "Delete"
    assert html =~ "id=\"keyboard\""
  end
end
