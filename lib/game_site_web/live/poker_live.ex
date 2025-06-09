defmodule GameSiteWeb.PokerLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores
  alias GameSiteWeb.Forms.PokerForm

  @suits ["spades", "clubs", "diamonds", "hearts"]
  # 11 = J, 12 = Q, 13 = K, 14 = A
  @ranks [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]

  def render(assigns) do
    ~H"""
    <p>Highest Score: {@highest_score}</p>
    <p>Score: {@score}</p>
    <%!-- <.simple_form id="answer-form" for={@form} phx-submit="answer"> --%>
    <%!-- I might want to add in phx-hook="FocusGuess below if I get the hook working properly" --%>
    <%!-- <.input type="number" field={@form[:guess]} label="Guess" value="" /> --%>
    <%!-- <.input type="number" field={@form[:wager]} label="Wager" min="1" max={@score} value={@wager} /> --%>
    <%!-- <:actions> --%>
    <%!-- <.button>Answer</.button> --%>
    <%!-- </:actions> --%>
    <%!-- </.simple_form> --%>

    <%!-- <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
      <div id="flash" phx-hook="AutoDismiss" class="flash-info transition-opacity duration-500">
        {msg}
      </div>
    <% end %> --%>

    <div>
      <p>
        Here is a helper function for the current problem you are working on.<br />
        If you want to see it or turn it off just toggle the helper button below.<br />
      </p>
      <label class="toggle-switch" phx-click="toggle">
        <input type="checkbox" class="toggle-switch-check" checked={@toggle} readonly />
        <span aria-hidden="true" class="toggle-switch-bar">
          <span class="toggle-switch-handle"></span>
        </span>
      </label>
      <%= if @toggle do %>
        <div style="white-space: pre; font-family: monospace;">
          <p>{@helper.first}</p>
          <p>{@helper.second}</p>
          <p>{@helper.third}</p>
          <p>{@helper.fourth}</p>
        </div>
      <% else %>
        <div style="white-space: pre; font-family: monospace;">
          <br /><br /><br /><br /><br /><br />
        </div>
      <% end %>
    </div>

    <div>
      This is my Poker Game. You will be able to draw 5 cards and then choose which ones to
      keep. Before you draw cards, before you pick new cards you will be able to increase your wager.
      You want to get the highest score possible. IF any any point you run out of score(money)
      the game will reset but it will still keep track of your highest score. <br /><br />#TODO:
      <br />Fix CSS
    </div>

    <.simple_form id="exit-form" for={@form} phx-submit="exit">
      <.input type="hidden" field={@form[:user_id]} value={@current_user.id} />
      <.input type="hidden" field={@form[:game_id]} value={2} />
      <.input type="hidden" field={@form[:score]} value={@highest_score} />
      <:actions>
        <.button>Exit and Save Score</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

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

  def choose(cards, hand, number) do
    [new_cards, cards] = Enum.reduce(1..number, [[], cards], fn _, [chosen, remaining] ->
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
      is_straight and is_flush and Enum.max(ranks) == 14 -> {:royal_flush, Enum.max(suits)}
      is_straight and is_flush -> {:straight_flush, Enum.max(sorted_ranks)}
      4 in Map.values(rank_counts) -> {:four_of_a_kind, Map.filter(rank_counts, fn {_key, value} -> value == 4 end)}
      Map.values(rank_counts) |> Enum.sort() == [2, 3] -> {:full_house, Map.filter(rank_counts, fn {_key, value} -> value == 3 end)}
      is_flush -> {:flush, Enum.max(suits)}
      is_straight -> {:straight, Enum.max(sorted_ranks)}
      3 in Map.values(rank_counts) -> {:three_of_a_kind, Map.filter(rank_counts, fn {_key, value} -> value == 3 end)}
      Enum.count(rank_counts, fn {_r, c} -> c == 2 end) == 2 -> {:two_pair, Map.filter(rank_counts, fn {_key, value} -> value == 2 end)}
      2 in Map.values(rank_counts) -> {:one_pair, Map.filter(rank_counts, fn {_key, value} -> value == 2 end)}
      true -> {:high_card, Enum.max(ranks)}
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
