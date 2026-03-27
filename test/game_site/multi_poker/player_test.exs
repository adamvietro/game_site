defmodule GameSite.MultiPoker.PlayerTest do
  use ExUnit.Case, async: true

  alias GameSite.MultiPoker.Player

  test "new/1 builds a player with defaults" do
    player = Player.new(123)

    assert player.player_id == 123
    assert player.ready? == false
    assert player.chips == 1000
    assert player.current_bet == 0
    assert player.folded? == false
    assert player.seat_position == nil
    assert player.hand == []
    assert player.connected? == true
  end

  test "new/2 applies passed options" do
    player =
      Player.new(123,
        ready?: true,
        chips: 500,
        current_bet: 25,
        folded?: true,
        seat_position: 3,
        hand: [:a_spades, :k_spades],
        connected?: false
      )

    assert player.player_id == 123
    assert player.ready? == true
    assert player.chips == 500
    assert player.current_bet == 25
    assert player.folded? == true
    assert player.seat_position == 3
    assert player.hand == [:a_spades, :k_spades]
    assert player.connected? == false
  end

  test "change/2 updates only passed fields" do
    player = Player.new(123)

    updated = Player.change(player, chips: 200, ready?: true)

    assert updated.player_id == 123
    assert updated.chips == 200
    assert updated.ready? == true
    assert updated.current_bet == 0
    assert updated.folded? == false
  end

  test "set_ready/2 updates ready state" do
    player = Player.new(123)

    updated = Player.set_ready(player, true)

    assert updated.ready? == true
    assert updated.player_id == 123
  end
end
