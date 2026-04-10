defmodule GameSite.Poker.GameLogic do
  alias GameSite.Poker.PokerHelpers, as: Helper

  defstruct hand: [],
            cards: [],
            state: "initial",
            wager: 10,
            score: 100,
            selected_cards: [],
            all_in: false

  def new_game() do
    %__MODULE__{}
  end

  def modify_game(%__MODULE__{} = game, changes) do
    struct(game, changes)
  end

  def advance_game(%__MODULE__{state: "initial"} = game, _params) do
    {hand, cards} = deal_cards()

    %{game | hand: hand, cards: cards, state: "dealt"}
  end

  def advance_game(%__MODULE__{state: "dealt"} = game, params) do
    raw_cards = Map.get(params, "replace", [])
    [new_hand, cards] = update_hand(selected_cards(raw_cards), game.hand, game.cards)

    %{game | hand: new_hand, cards: cards, state: "final"}
  end

  def advance_game(%__MODULE__{state: "final"} = game, _params) do
    case Helper.classify(game.hand) do
      {:high_card, _rank} ->
        score = game.score - game.wager

        %{game | state: "reset", all_in: false, score: score, wager: min(score, game.wager)}

      {:one_pair, [rank]} ->
        if rank >= 11 do
          %{game | score: game.score + game.wager, state: "reset", all_in: false}
        else
          score = game.score - game.wager

          %{
            game
            | state: "reset",
              all_in: false,
              score: score,
              wager: min(score, game.wager)
          }
        end

      {_hand, _rank_suit} ->
        score = game.score + game.wager

        %{game | score: score, state: "reset", all_in: false}
    end
  end

  def advance_game(%__MODULE__{state: "reset"} = game, _params) do
    %{game | state: "initial", all_in: false}
  end

  defp selected_cards([]), do: []

  defp selected_cards(raw_cards) do
    Enum.map(raw_cards, fn string ->
      [rank, suit] = String.split(string, ":")
      {String.to_integer(rank), suit}
    end)
  end

  def deal_cards() do
    Helper.cards()
    |> Helper.shuffle()
    |> Helper.choose_5()
  end

  defp update_hand(selected_cards, hand, cards) do
    number_of_cards =
      length(selected_cards)

    new_hand = Helper.remove_cards(selected_cards, hand)
    Helper.choose(cards, new_hand, number_of_cards)
  end
end
