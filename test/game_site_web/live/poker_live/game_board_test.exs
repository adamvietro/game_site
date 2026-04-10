defmodule GameSiteWeb.Live.PokerLive.GameBoardTest do
  use GameSiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component, only: [to_form: 1]

  alias GameSiteWeb.PokerLive.GameBoard

  describe "game_board/1" do
    test "renders hand and wager section inside the form" do
      html =
        render_component(&GameBoard.game_board/1,
          form: to_form(%{"wager" => 10}),
          hand: [{10, "hearts"}, {11, "spades"}],
          score: 100,
          wager: 10,
          state: "initial",
          all_in: false
        )

      assert html =~ "phx-submit=\"advance\""
      assert html =~ "10 of Hearts"
      assert html =~ "11 of Spades"
      assert html =~ "Deal Cards"
      assert html =~ "All-In"
    end
  end

  describe "hand/1" do
    test "renders cards in hand" do
      html =
        render_component(&GameBoard.hand/1,
          hand: [{14, "spades"}, {9, "clubs"}]
        )

      assert html =~ "14 of Spades"
      assert html =~ "9 of Clubs"
      assert html =~ "value=\"14:spades\""
      assert html =~ "value=\"9:clubs\""
      assert html =~ "/images/cards/spades_14.png"
      assert html =~ "/images/cards/clubs_9.png"
    end

    test "renders no cards when hand is empty" do
      html =
        render_component(&GameBoard.hand/1,
          hand: []
        )

      refute html =~ "<img"
    end
  end

  describe "wager/1" do
    test "initial state without all in shows wager controls" do
      html =
        render_component(&GameBoard.wager/1,
          wager: 10,
          score: 100,
          state: "initial",
          all_in: false,
          form: to_form(%{"wager" => 10})
        )

      assert html =~ "Wager"
      assert html =~ "decrease_wager"
      assert html =~ "increase_wager"
      assert html =~ "all-in"
      assert html =~ "Deal Cards"
      assert html =~ "value=\"10\""
    end

    test "initial state with all in hides wager adjustment buttons" do
      html =
        render_component(&GameBoard.wager/1,
          wager: 100,
          score: 100,
          state: "initial",
          all_in: true,
          form: to_form(%{"wager" => 100})
        )

      refute html =~ "decrease_wager"
      refute html =~ "increase_wager"
      refute html =~ "all-in"
      assert html =~ "Deal Cards"
      assert html =~ "value=\"100\""
    end

    test "dealt state shows replace selected cards button" do
      html =
        render_component(&GameBoard.wager/1,
          wager: 20,
          score: 100,
          state: "dealt",
          all_in: false,
          form: to_form(%{"wager" => 20})
        )

      assert html =~ "Replace Selected Cards"
      refute html =~ "Deal Cards"
    end

    test "final state shows resolve button" do
      html =
        render_component(&GameBoard.wager/1,
          wager: 20,
          score: 100,
          state: "final",
          all_in: false,
          form: to_form(%{"wager" => 20})
        )

      assert html =~ "Resolve"
      refute html =~ "Deal Cards"
    end

    test "reset state with score above zero shows new hand button" do
      html =
        render_component(&GameBoard.wager/1,
          wager: 20,
          score: 50,
          state: "reset",
          all_in: false,
          form: to_form(%{"wager" => 20})
        )

      assert html =~ "New Hand"
      assert html =~ "phx-click=\"new-hand\""
      assert html =~ "invisible"
    end

    test "reset state with zero score shows reset game button" do
      html =
        render_component(&GameBoard.wager/1,
          wager: 10,
          score: 0,
          state: "reset",
          all_in: false,
          form: to_form(%{"wager" => 10})
        )

      assert html =~ "Reset Game"
      assert html =~ "phx-click=\"reset\""
      assert html =~ "invisible"
    end
  end
end
