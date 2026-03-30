defmodule GameSite.MultiPoker.GameLogic do
  alias GameSite.MultiPoker.{Room, Player, Deck}

  def start_hand(%Room{} = room) do
    room
    |> advance_to_next_dealer()
    |> reset_room_for_new_hand()
    |> reset_players_for_new_hand()
    |> shuffle_new_deck()
    |> deal_player_hole_cards()
    |> set_first_player_turn()
  end

  def advance_phase_and_deal(%Room{phase: phase} = room) do
    case phase do
      :pre_flop -> deal_community_cards(room, 3, :flop)
      :flop -> deal_community_cards(room, 1, :turn)
      :turn -> deal_community_cards(room, 1, :river)
      :river -> Room.change(room, phase: :showdown)
    end
  end

  def player_bet(%Room{current_player_turn: current_player_turn} = room, player_id, amount)
      when current_player_turn != player_id or amount <= 0 do
    room
  end

  def player_bet(%Room{players: players, pot: pot} = room, player_id, amount) do
    case Map.fetch(players, player_id) do
      {:ok, player} ->
        updated_player =
          Player.change(player,
            current_bet: player.current_bet + amount,
            chips: player.chips - amount
          )

        new_players = Map.put(players, player_id, updated_player)

        %Room{
          room
          | players: new_players,
            pot: pot + amount
        }
        |> advance_to_next_player()

      :error ->
        room
    end
  end

  def player_fold(%Room{current_player_turn: current_player_turn} = room, player_id)
      when current_player_turn != player_id do
    room
  end

  def player_fold(%Room{players: players} = room, player_id) do
    case Map.fetch(players, player_id) do
      {:ok, player} ->
        updated_player = Player.change(player, folded?: true)
        new_players = Map.put(players, player_id, updated_player)

        %Room{room | players: new_players}
        |> advance_to_next_player()

      :error ->
        room
    end
  end

  defp deal_community_cards(%Room{deck: deck, community_cards: board} = room, n, next_phase) do
    [cards, new_deck] = Deck.choose_n_cards(deck, n)
    ordered_cards = Enum.reverse(cards)

    Room.change(room,
      deck: new_deck,
      community_cards: board ++ ordered_cards,
      phase: next_phase
    )
  end

  defp reset_room_for_new_hand(%Room{} = room) do
    Room.change(room,
      phase: :pre_flop,
      deck: [],
      community_cards: [],
      current_player_turn: nil,
      pot: 0,
      current_hand_number: room.current_hand_number + 1
    )
  end

  defp reset_players_for_new_hand(%Room{players: players} = room) do
    new_players =
      Enum.into(players, %{}, fn {player_id, player} ->
        updated_player =
          Player.change(player,
            ready?: false,
            current_bet: 0,
            folded?: false,
            hand: []
          )

        {player_id, updated_player}
      end)

    %Room{room | players: new_players}
  end

  defp shuffle_new_deck(%Room{} = room) do
    shuffled_deck =
      Deck.create_deck()
      |> Deck.shuffle_cards()

    %Room{room | deck: shuffled_deck}
  end

  defp deal_player_hole_cards(%Room{deck: deck, players: players} = room) do
    ordered_players =
      players
      |> Map.values()
      |> Enum.sort_by(& &1.seat_position)

    {new_deck, new_players} =
      Enum.reduce(ordered_players, {deck, %{}}, fn player, {deck_acc, players_acc} ->
        [new_cards, next_deck] = Deck.choose_n_cards(deck_acc, 2)

        updated_player =
          Player.change(player, hand: Enum.reverse(new_cards))

        {next_deck, Map.put(players_acc, player.player_id, updated_player)}
      end)

    %Room{room | deck: new_deck, players: new_players}
  end

  defp set_first_player_turn(%Room{dealer_player_id: dealer_player_id} = room) do
    case next_seated_player(room, dealer_player_id) do
      nil ->
        room

      next_player ->
        Room.change(room, current_player_turn: next_player.player_id)
    end
  end

  defp advance_to_next_player(%Room{current_player_turn: current_player_turn} = room) do
    case next_active_player(room, current_player_turn) do
      nil ->
        room

      next_player ->
        Room.change(room, current_player_turn: next_player.player_id)
    end
  end

  defp advance_to_next_dealer(%Room{dealer_player_id: dealer_player_id} = room) do
    case next_seated_player(room, dealer_player_id) do
      nil ->
        room

      next_player ->
        Room.change(room, dealer_player_id: next_player.player_id)
    end
  end

  defp ordered_players(%Room{players: players}) do
    players
    |> Map.values()
    |> Enum.sort_by(& &1.seat_position)
  end

  defp next_active_player(%Room{} = room, current_player_id) do
    players = ordered_players(room)

    case Enum.find_index(players, fn player -> player.player_id == current_player_id end) do
      nil ->
        Enum.find(players, fn player -> not player.folded? end)

      current_index ->
        players
        |> rotate_after(current_index)
        |> Enum.find(fn player -> not player.folded? end)
    end
  end

  defp next_seated_player(%Room{} = room, current_player_id) do
    players = ordered_players(room)

    case Enum.find_index(players, fn player -> player.player_id == current_player_id end) do
      nil ->
        List.first(players)

      current_index ->
        players
        |> rotate_after(current_index)
        |> List.first()
    end
  end

  defp rotate_after(players, index) do
    {left, right} = Enum.split(players, index + 1)
    right ++ left
  end
end
