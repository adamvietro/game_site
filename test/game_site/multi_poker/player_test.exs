defmodule GameSite.MultiPoker.PlayerTest do
  use ExUnit.Case, async: true

  alias GameSite.MultiPoker.Player

  describe "new/3" do
    test "builds a player with defaults" do
      player = Player.new(123, 123)

      assert player.player_id == 123
      assert player.viewer_id == 123
      assert player.ready? == false
      assert player.chips == 1000
      assert player.current_bet == 0
      assert player.folded? == false
      assert player.seat_position == nil
      assert player.hand == []
      assert player.connected? == true
      assert player.waiting? == false
      assert player.total_contribution == 0
      assert player.busted? == false
    end

    test "applies passed options" do
      player =
        Player.new(123, 456,
          ready?: true,
          chips: 500,
          current_bet: 25,
          folded?: true,
          seat_position: 3,
          hand: [:a_spades, :k_spades],
          connected?: false,
          waiting?: true,
          total_contribution: 75,
          busted?: true
        )

      assert player.player_id == 123
      assert player.viewer_id == 456
      assert player.ready? == true
      assert player.chips == 500
      assert player.current_bet == 25
      assert player.folded? == true
      assert player.seat_position == 3
      assert player.hand == [:a_spades, :k_spades]
      assert player.connected? == false
      assert player.waiting? == true
      assert player.total_contribution == 75
      assert player.busted? == true
    end

    test "uses defaults for options not provided" do
      player =
        Player.new(123, 456,
          chips: 750,
          waiting?: true
        )

      assert player.player_id == 123
      assert player.viewer_id == 456
      assert player.ready? == false
      assert player.chips == 750
      assert player.current_bet == 0
      assert player.folded? == false
      assert player.seat_position == nil
      assert player.hand == []
      assert player.connected? == true
      assert player.waiting? == true
      assert player.total_contribution == 0
      assert player.busted? == false
    end
  end

  describe "change/2" do
    test "updates only passed fields" do
      player = Player.new(123, 123)

      updated =
        Player.change(player,
          chips: 200,
          ready?: true
        )

      assert updated.player_id == 123
      assert updated.viewer_id == 123
      assert updated.chips == 200
      assert updated.ready? == true
      assert updated.current_bet == 0
      assert updated.folded? == false
      assert updated.waiting? == false
      assert updated.total_contribution == 0
      assert updated.busted? == false
    end

    test "can update newer poker-related fields" do
      player = Player.new(123, 123)

      updated =
        Player.change(player,
          waiting?: true,
          total_contribution: 150,
          busted?: true,
          hand: [{14, "spades"}, {14, "hearts"}]
        )

      assert updated.player_id == 123
      assert updated.viewer_id == 123
      assert updated.waiting? == true
      assert updated.total_contribution == 150
      assert updated.busted? == true
      assert updated.hand == [{14, "spades"}, {14, "hearts"}]
      assert updated.chips == 1000
      assert updated.ready? == false
    end
  end

  describe "set_ready/2" do
    test "updates ready state to true" do
      player = Player.new(123, 123)

      updated = Player.set_ready(player, true)

      assert updated.ready? == true
      assert updated.player_id == 123
      assert updated.viewer_id == 123
      assert updated.chips == 1000
    end

    test "updates ready state to false" do
      player = Player.new(123, 123, ready?: true)

      updated = Player.set_ready(player, false)

      assert updated.ready? == false
      assert updated.player_id == 123
      assert updated.viewer_id == 123
    end
  end
end
