defmodule GameSite.MultiPoker.HandEvaluator do
  alias GameSite.MultiPoker.{Player, Room}

  def evaluate_hands(%Room{community_cards: community_cards, players: players}) do
    players
    |> Enum.map(fn {_id, %Player{hand: hand, player_id: player_id}} ->
      {player_id, community_cards ++ hand}
    end)
    |> Enum.sort_by(&rank_hand/1, :desc)
  end

  def rank_hand({_player_id, cards}) do
    score_hand(cards)
  end

  def score_hand(cards) do
    cond do
      royal_flush_value(cards) != nil ->
        {get_rank(:royal_flush), [royal_flush_value(cards)]}

      straight_flush_value(cards) != nil ->
        {get_rank(:straight_flush), [straight_flush_value(cards)]}

      four_of_a_kind_value(cards) != nil ->
        {get_rank(:four_of_a_kind), four_of_a_kind_value(cards)}

      full_house_value(cards) != nil ->
        {get_rank(:full_house), full_house_value(cards)}

      flush_value(cards) != nil ->
        {get_rank(:flush), flush_value(cards)}

      straight_value(cards) != nil ->
        {get_rank(:straight), [straight_value(cards)]}

      three_of_a_kind_value(cards) != nil ->
        {get_rank(:three_of_a_kind), three_of_a_kind_value(cards)}

      two_pair_value(cards) != nil ->
        {get_rank(:two_pair), two_pair_value(cards)}

      pair_value(cards) != nil ->
        {get_rank(:pair), pair_value(cards)}

      true ->
        {get_rank(:high_card), high_card_value(cards)}
    end
  end

  def get_rank(:high_card), do: 1
  def get_rank(:pair), do: 2
  def get_rank(:two_pair), do: 3
  def get_rank(:three_of_a_kind), do: 4
  def get_rank(:straight), do: 5
  def get_rank(:flush), do: 6
  def get_rank(:full_house), do: 7
  def get_rank(:four_of_a_kind), do: 8
  def get_rank(:straight_flush), do: 9
  def get_rank(:royal_flush), do: 10

  def royal_flush_value(cards) do
    case straight_flush_value(cards) do
      14 -> 14
      _ -> nil
    end
  end

  def straight_flush_value(cards) do
    cards
    |> Enum.group_by(fn {_value, suit} -> suit end, fn {value, _suit} -> value end)
    |> Enum.map(fn {_suit, values} ->
      values
      |> Enum.uniq()
      |> add_wheel_ace()
      |> Enum.sort()
      |> straight_high_card_from_values()
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.max(fn -> nil end)
  end

  def four_of_a_kind_value(cards) do
    counts = value_frequencies(cards)

    case Enum.find(counts, fn {_value, count} -> count == 4 end) do
      nil ->
        nil

      {quad_value, _count} ->
        kicker =
          counts
          |> Enum.reject(fn {value, _count} -> value == quad_value end)
          |> Enum.map(fn {value, _count} -> value end)
          |> Enum.max(fn -> nil end)

        [quad_value, kicker]
    end
  end

  def full_house_value(cards) do
    counts = value_frequencies(cards)

    trips =
      counts
      |> Enum.filter(fn {_value, count} -> count >= 3 end)
      |> Enum.map(fn {value, _count} -> value end)
      |> Enum.sort(:desc)

    case trips do
      [] ->
        nil

      [top_trip | remaining_trips] ->
        pair_candidates =
          counts
          |> Enum.reject(fn {value, count} ->
            value == top_trip or count < 2
          end)
          |> Enum.map(fn {value, _count} -> value end)

        pair_value =
          (remaining_trips ++ pair_candidates)
          |> Enum.sort(:desc)
          |> List.first()

        if pair_value do
          [top_trip, pair_value]
        else
          nil
        end
    end
  end

  def flush_value(cards) do
    cards
    |> Enum.group_by(fn {_value, suit} -> suit end, fn {value, _suit} -> value end)
    |> Enum.map(fn {_suit, values} ->
      if length(values) >= 5 do
        values
        |> Enum.sort(:desc)
        |> Enum.take(5)
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.max(fn -> nil end)
  end

  def straight_value(cards) do
    cards
    |> Enum.map(fn {value, _suit} -> value end)
    |> Enum.uniq()
    |> add_wheel_ace()
    |> Enum.sort()
    |> straight_high_card_from_values()
  end

  def three_of_a_kind_value(cards) do
    counts = value_frequencies(cards)

    case counts
         |> Enum.filter(fn {_value, count} -> count == 3 end)
         |> Enum.map(fn {value, _count} -> value end)
         |> Enum.sort(:desc)
         |> List.first() do
      nil ->
        nil

      trip_value ->
        kickers =
          counts
          |> Enum.reject(fn {value, _count} -> value == trip_value end)
          |> Enum.map(fn {value, _count} -> value end)
          |> Enum.sort(:desc)
          |> Enum.take(2)

        [trip_value | kickers]
    end
  end

  def two_pair_value(cards) do
    counts = value_frequencies(cards)

    pairs =
      counts
      |> Enum.filter(fn {_value, count} -> count >= 2 end)
      |> Enum.map(fn {value, _count} -> value end)
      |> Enum.sort(:desc)

    case pairs do
      [high_pair, low_pair | _rest] ->
        kicker =
          counts
          |> Enum.reject(fn {value, _count} -> value in [high_pair, low_pair] end)
          |> Enum.map(fn {value, _count} -> value end)
          |> Enum.max(fn -> nil end)

        [high_pair, low_pair, kicker]

      _ ->
        nil
    end
  end

  def pair_value(cards) do
    counts = value_frequencies(cards)

    case counts
         |> Enum.filter(fn {_value, count} -> count == 2 end)
         |> Enum.map(fn {value, _count} -> value end)
         |> Enum.sort(:desc)
         |> List.first() do
      nil ->
        nil

      pair_value ->
        kickers =
          counts
          |> Enum.reject(fn {value, _count} -> value == pair_value end)
          |> Enum.map(fn {value, _count} -> value end)
          |> Enum.sort(:desc)
          |> Enum.take(3)

        [pair_value | kickers]
    end
  end

  def high_card_value(cards) do
    cards
    |> Enum.map(fn {value, _suit} -> value end)
    |> Enum.uniq()
    |> Enum.sort(:desc)
    |> Enum.take(5)
  end

  defp straight_high_card_from_values(values) do
    values
    |> Enum.chunk_every(5, 1, :discard)
    |> Enum.filter(&consecutive?/1)
    |> Enum.map(&List.last/1)
    |> Enum.max(fn -> nil end)
  end

  defp consecutive?([a, b, c, d, e]) do
    b == a + 1 and c == b + 1 and d == c + 1 and e == d + 1
  end

  defp add_wheel_ace(values) do
    if 14 in values do
      [1 | values]
    else
      values
    end
  end

  defp value_frequencies(cards) do
    cards
    |> Enum.frequencies_by(fn {value, _suit} -> value end)
    |> Enum.to_list()
  end
end
