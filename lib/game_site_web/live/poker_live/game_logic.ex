defmodule GameSiteWeb.Live.PokerLive.GameLogic do
  alias GameSiteWeb.PokerLive.PokerHelpers, as: Helper

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

  def advance_game(%__MODULE__{} = game) do
    case game.state do
      "initial" ->
        {hand, cards} = deal_cards()

        %{game | hand: hand, cards: cards, state: "dealt"}

      "dealt" ->
        [new_hand, cards] = update_hand(game.selected_cards, game.hand, game.cards)

        %{game | hand: new_hand, cards: cards, state: "final"}

      "final" ->
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

      "reset" ->
        %{game | state: "initial", all_in: false}
    end

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
