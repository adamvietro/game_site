defmodule GameSiteWeb.Live.WordleLive.GameBoardTest do
  use ExUnit.Case, async: true

  alias GameSiteWeb.Live.WordleLive.GameBoard

  test "get_keyboard_row_attr for top row" do
    assert GameBoard.get_keyboard_row_attr(:top) == %{
             letters: [:q, :w, :e, :r, :t, :y, :u, :i, :o, :p],
             class: "grid grid-cols-10 gap-1 sm:gap-2"
           }
  end

  test "get_keyboard_row_attr for middle row" do
    assert GameBoard.get_keyboard_row_attr(:middle) == %{
             letters: [:a, :s, :d, :f, :g, :h, :j, :k, :l],
             class: "grid grid-cols-9 gap-1 sm:gap-2"
           }
  end

  test "get_keyboard_row_attr for bottom row" do
    assert GameBoard.get_keyboard_row_attr(:bottom) == %{
             letters: [:z, :x, :c, :v, :b, :n, :m],
             class: "grid grid-cols-7 gap-1 sm:gap-2"
           }
  end

  test "get_labels returns all board labels in order" do
    entries = %{
      first: %{l1: "h", l2: "e", l3: "l", l4: "l", l5: "o"},
      second: %{l1: "w", l2: "o", l3: "r", l4: "l", l5: "d"},
      third: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."},
      fourth: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."},
      fifth: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."},
      sixth: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."}
    }

    assert GameBoard.get_labels(entries) == [
             "h",
             "e",
             "l",
             "l",
             "o",
             "w",
             "o",
             "r",
             "l",
             "d",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             ".",
             "."
           ]
  end
end
