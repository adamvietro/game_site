defmodule GameSiteWeb.PokerHelpers do
  @suits ["spades", "clubs", "diamonds", "hearts"]
  @ranks [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]

  def cards do
    for rank <- @ranks, suit <- @suits do
      {rank, suit}
    end
  end

  def shuffle(cards) do
    Enum.shuffle(cards)
  end

  def choose_5(cards) do
    {card1, cards} = List.pop_at(cards, 1)
    {card2, cards} = List.pop_at(cards, 1)
    {card3, cards} = List.pop_at(cards, 1)
    {card4, cards} = List.pop_at(cards, 1)
    {card5, cards} = List.pop_at(cards, 1)

    hand =
      [card1, card2, card3, card4, card5]
      |> Enum.sort()

    {hand, cards}
  end

  def choose(cards, hand, 0), do: [hand, cards]
  def choose(cards, hand, number) do
    [new_cards, cards] =
      Enum.reduce(1..number, [[], cards], fn _, [chosen, remaining] ->
        {card, new_remaining} = List.pop_at(remaining, 0)
        [[card | chosen], new_remaining]
      end)

    [new_cards ++ hand, cards]
  end

  def remove_cards(list, hand) do
    Enum.reject(hand, fn card ->
      card in list
    end)
  end

  def classify(hand) when length(hand) == 5 do
    {ranks, suits} = Enum.unzip(hand)
    rank_counts = Enum.frequencies(ranks)
    suit_counts = Enum.frequencies(suits)

    is_flush = map_size(suit_counts) == 1
    sorted_ranks = Enum.sort(ranks)
    is_straight = straight?(sorted_ranks)

    cond do
      is_straight and is_flush and Enum.max(ranks) == 14 ->
        {:royal_flush, Enum.max(suits)}

      is_straight and is_flush ->
        {:straight_flush, Enum.max(sorted_ranks)}

      4 in Map.values(rank_counts) ->
        {:four_of_a_kind, Map.filter(rank_counts, fn {_key, value} -> value == 4 end)}

      Map.values(rank_counts) |> Enum.sort() == [2, 3] ->
        {:full_house, Map.filter(rank_counts, fn {_key, value} -> value == 3 end)}

      is_flush ->
        {:flush, Enum.max(suits)}

      is_straight ->
        {:straight, Enum.max(sorted_ranks)}

      3 in Map.values(rank_counts) ->
        {:three_of_a_kind, Map.filter(rank_counts, fn {_key, value} -> value == 3 end)}

      Enum.count(rank_counts, fn {_r, c} -> c == 2 end) == 2 ->
        {:two_pair, Map.filter(rank_counts, fn {_key, value} -> value == 2 end)}

      2 in Map.values(rank_counts) ->
        {:one_pair, Map.filter(rank_counts, fn {_key, value} -> value == 2 end)}

      true ->
        {:high_card, Enum.max(ranks)}
    end
  end

  def straight?(ranks) do
    sorted = Enum.sort(ranks)
    # Handle ace-low straight: A-2-3-4-5
    Enum.chunk_every(sorted, 2, 1, :discard)
    |> Enum.all?(fn [a, b] -> b - a == 1 end) or
      sorted == [2, 3, 4, 5, 14]
  end
end
