defmodule GameSite.MultiPoker.Deck do
  @suits ["spades", "clubs", "diamonds", "hearts"]
  @ranks [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]

  def create_deck do
    for rank <- @ranks, suit <- @suits do
      {rank, suit}
    end
  end

  def shuffle_cards(deck) do
    Enum.shuffle(deck)
  end

  def choose_n_cards(deck, 0), do: [[], deck]

  def choose_n_cards(deck, n) do
    [dealt_cards, deck] =
      Enum.reduce(1..n, [[], deck], fn _, [chosen, remaining] ->
        {card, new_remaining} = List.pop_at(remaining, 0)
        [[card | chosen], new_remaining]
      end)

    [dealt_cards, deck]
  end
end
