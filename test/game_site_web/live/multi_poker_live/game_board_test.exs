defmodule GameSiteWeb.MultiPokerLive.GameBoardTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias GameSiteWeb.MultiPokerLive.GameBoard

  defp sample_players() do
    %{
      1 => %{
        player_id: 1,
        viewer_id: "user:1",
        hand: [{14, "spades"}, {13, "hearts"}],
        chips: 1000,
        current_bet: 50,
        folded?: false,
        ready?: false
      },
      2 => %{
        player_id: 2,
        viewer_id: "guest:abc",
        hand: [{10, "clubs"}, {9, "diamonds"}],
        chips: 850,
        current_bet: 100,
        folded?: false,
        ready?: true
      },
      3 => %{
        player_id: 3,
        viewer_id: "guest:def",
        hand: [{8, "hearts"}, {7, "spades"}],
        chips: 500,
        current_bet: 0,
        folded?: true,
        ready?: false
      }
    }
  end

  describe "score_board/1" do
    test "renders phase, pot, and current round max bet" do
      html =
        render_component(&GameBoard.score_board/1,
          phase: :pre_flop,
          current_player_turn: 2,
          pot: 150,
          dealer_player_id: 1,
          current_round_max_bet: 100,
          winning_hand: nil
        )

      assert html =~ "Table Info"
      assert html =~ "Phase"
      assert html =~ "Pre Flop"
      assert html =~ "Pot"
      assert html =~ "150"
      assert html =~ "Current Round Max Bet"
      assert html =~ "100"
    end
  end

  describe "game_table/1" do
    test "shows community cards and reveals only current viewer hand before showdown" do
      html =
        render_component(&GameBoard.game_table/1,
          players: sample_players(),
          current_player_turn: 2,
          community_cards: [{14, "spades"}, {13, "hearts"}, {12, "clubs"}],
          current_viewer_id: "user:1",
          phase: :pre_flop,
          winning_player_id: nil,
          dealer_player_id: 2
        )

      assert html =~ "Community Cards"
      assert html =~ "A of ♠"
      assert html =~ "K of ♥"
      assert html =~ "Q of ♣"

      assert html =~ "Player 1"
      assert html =~ "Player 2"
      assert html =~ "Player 3"

      assert html =~ "You"
      assert html =~ "Dealer"
      assert html =~ "(Current Turn)"
      assert html =~ "(Folded)"

      assert html =~ "Chips: 1000"
      assert html =~ "Current Bet: 50"

      assert html =~ "Hidden card"
    end

    test "reveals all hands during showdown" do
      html =
        render_component(&GameBoard.game_table/1,
          players: sample_players(),
          current_player_turn: 2,
          community_cards: [],
          current_viewer_id: "user:1",
          phase: :showdown,
          winning_player_id: nil,
          dealer_player_id: 2
        )

      assert html =~ "A of ♠"
      assert html =~ "K of ♥"
      assert html =~ "10 of ♣"
      assert html =~ "9 of ♦"
      assert html =~ "8 of ♥"
      assert html =~ "7 of ♠"
    end

    test "reveals all hands when there is a winning player id even before showdown" do
      html =
        render_component(&GameBoard.game_table/1,
          players: sample_players(),
          current_player_turn: 2,
          community_cards: [],
          current_viewer_id: "user:1",
          phase: :river,
          winning_player_id: 2,
          dealer_player_id: 2
        )

      assert html =~ "10 of ♣"
      assert html =~ "9 of ♦"
      assert html =~ "8 of ♥"
      assert html =~ "7 of ♠"
    end
  end

  describe "player_hand/1" do
    test "renders player labels and stats" do
      html =
        render_component(&GameBoard.player_hand/1,
          player_id: 2,
          player_hand: [{10, "clubs"}, {9, "diamonds"}],
          current_player_turn: 2,
          show_hand: true,
          chips: 850,
          current_bet: 100,
          folded?: true,
          ready?: false,
          winning_player_id: nil,
          dealer_player_id: 2,
          is_current_viewer: true
        )

      assert html =~ "Player 2"
      assert html =~ "Dealer"
      assert html =~ "You"
      assert html =~ "(Current Turn)"
      assert html =~ "(Folded)"
      assert html =~ "Player Stats"
      assert html =~ "Chips: 850"
      assert html =~ "Current Bet: 100"
      assert html =~ "10 of ♣"
      assert html =~ "9 of ♦"
    end

    test "hides cards when show_hand is false" do
      html =
        render_component(&GameBoard.player_hand/1,
          player_id: 3,
          player_hand: [{8, "hearts"}, {7, "spades"}],
          current_player_turn: 2,
          show_hand: false,
          chips: 500,
          current_bet: 0,
          folded?: false,
          ready?: false,
          winning_player_id: nil,
          dealer_player_id: nil,
          is_current_viewer: false
        )

      assert html =~ "Hidden card"
      refute html =~ "8 of ♥"
      refute html =~ "7 of ♠"
    end
  end

  describe "community_cards/1" do
    test "fills empty community slots with hidden cards" do
      html =
        render_component(&GameBoard.community_cards/1,
          community_cards: [{14, "spades"}, {13, "hearts"}]
        )

      assert html =~ "A of ♠"
      assert html =~ "K of ♥"

      hidden_count = html |> String.split("Hidden card") |> length() |> Kernel.-(1)
      assert hidden_count == 3
    end
  end

  describe "card_row/1" do
    test "renders visible cards when reveal is true" do
      html =
        render_component(&GameBoard.card_row/1,
          cards: [{11, "diamonds"}, {10, "clubs"}],
          total_slots: 2,
          reveal?: true
        )

      assert html =~ "J of ♦"
      assert html =~ "10 of ♣"
      refute html =~ "Hidden card"
    end

    test "renders hidden cards when reveal is false" do
      html =
        render_component(&GameBoard.card_row/1,
          cards: [{11, "diamonds"}, {10, "clubs"}],
          total_slots: 2,
          reveal?: false
        )

      hidden_count = html |> String.split("Hidden card") |> length() |> Kernel.-(1)
      assert hidden_count == 2

      refute html =~ "J of ♦"
      refute html =~ "10 of ♣"
    end
  end

  describe "player_actions/1" do
    test "renders controls when room is playing" do
      html =
        render_component(&GameBoard.player_actions/1,
          room_status: :playing,
          action_state: :your_turn,
          player_chips: 900,
          player_current_bet: 50,
          bet_amount: 25
        )

      assert html =~ "Player Actions"
      assert html =~ "Your Chips"
      assert html =~ "900"
      assert html =~ "Your Current Bet"
      assert html =~ "50"
      assert html =~ "Amount Needed"
      assert html =~ "25"
    end

    test "renders nothing when room is not playing" do
      html =
        render_component(&GameBoard.player_actions/1,
          room_status: :waiting,
          action_state: :your_turn,
          player_chips: 900,
          player_current_bet: 50,
          bet_amount: 25
        )

      refute html =~ "Player Actions"
      refute html =~ "Your Chips"
    end
  end

  describe "player_controls/1" do
    test "renders enabled controls on your turn" do
      html =
        render_component(&GameBoard.player_controls/1,
          disabled: false,
          bet_amount: 0,
          player_chips: 1000,
          player_current_bet: 0
        )

      assert html =~ ~s(phx-click="player-fold")
      assert html =~ ~s(phx-click="player-check")
      assert html =~ ~s(phx-click="player-all-in")
      assert html =~ ~s(phx-submit="player-bet")
      assert html =~ ~s(min="0")
      assert html =~ ~s(max="1000")

      refute html =~ ~s(cursor-not-allowed)
    end

    test "disables check when amount needed is greater than zero" do
      html =
        render_component(&GameBoard.player_controls/1,
          disabled: false,
          bet_amount: 25,
          player_chips: 1000,
          player_current_bet: 0
        )

      assert html =~ "Amount Needed"
      assert html =~ "25"
      assert html =~ ~s(phx-click="player-check")
      assert html =~ ~s(disabled)
    end

    test "disables all controls when disabled is true" do
      html =
        render_component(&GameBoard.player_controls/1,
          disabled: true,
          bet_amount: 0,
          player_chips: 1000,
          player_current_bet: 0
        )

      assert html =~ ~s(cursor-not-allowed)
      assert html =~ ~s(opacity-50)
      assert html =~ ~s(phx-click="player-fold")
      assert html =~ ~s(phx-click="player-check")
      assert html =~ ~s(phx-click="player-all-in")
    end
  end

  describe "join_game/1" do
    test "shows join button when player is not joined and room is waiting and not full" do
      html =
        render_component(&GameBoard.join_game/1,
          viewer_state: %{action_state: :not_joined},
          room_status: :waiting,
          room_full: false
        )

      assert html =~ "Join Game"
      refute html =~ "Leave Game"
    end

    test "shows leave button when player is joined and room is waiting" do
      html =
        render_component(&GameBoard.join_game/1,
          viewer_state: %{action_state: :waiting},
          room_status: :waiting,
          room_full: false
        )

      assert html =~ "Leave Game"
      refute html =~ "Join Game"
    end

    test "shows no buttons when room is full for not joined player" do
      html =
        render_component(&GameBoard.join_game/1,
          viewer_state: %{action_state: :not_joined},
          room_status: :waiting,
          room_full: true
        )

      refute html =~ "Join Game"
      refute html =~ "Leave Game"
    end

    test "shows no buttons when room is playing" do
      html =
        render_component(&GameBoard.join_game/1,
          viewer_state: %{action_state: :not_joined},
          room_status: :playing,
          room_full: false
        )

      refute html =~ "Join Game"
      refute html =~ "Leave Game"
    end
  end

  describe "player_ready/1" do
    test "shows ready button when waiting and eligible" do
      html =
        render_component(&GameBoard.player_ready/1,
          game_state: :waiting,
          viewer_state: %{action_state: :waiting, ready?: false, busted?: false}
        )

      assert html =~ "Ready!"
    end

    test "does not show ready button when not joined" do
      html =
        render_component(&GameBoard.player_ready/1,
          game_state: :waiting,
          viewer_state: %{action_state: :not_joined, ready?: false, busted?: false}
        )

      refute html =~ "Ready!"
    end

    test "does not show ready button when already ready" do
      html =
        render_component(&GameBoard.player_ready/1,
          game_state: :waiting,
          viewer_state: %{action_state: :waiting, ready?: true, busted?: false}
        )

      refute html =~ "Ready!"
    end

    test "does not show ready button when busted" do
      html =
        render_component(&GameBoard.player_ready/1,
          game_state: :waiting,
          viewer_state: %{action_state: :waiting, ready?: false, busted?: true}
        )

      refute html =~ "Ready!"
    end

    test "does not show ready button when game is not waiting" do
      html =
        render_component(&GameBoard.player_ready/1,
          game_state: :playing,
          viewer_state: %{action_state: :waiting, ready?: false, busted?: false}
        )

      refute html =~ "Ready!"
    end
  end
end
