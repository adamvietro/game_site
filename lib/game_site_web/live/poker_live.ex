defmodule GameSiteWeb.PokerLive do
  use GameSiteWeb, :live_view

  alias GameSiteWeb.Live.Component, as: LiveComponent
  alias GameSiteWeb.Live.PokerLive.{Component, GameBoard}
  alias GameSiteWeb.PokerForm
  alias GameSiteWeb.PokerHelpers, as: Helper
  alias GameSite.Scores.ScoreHandler

  @all_in_list ["initial", "dealt", "final"]

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-4 space-y-8">
      <Component.instructions />
      <LiveComponent.score_board
        highest_score={@highest_score}
        current_score={@score}
        current_bet={@wager}
      />

      <%!-- <!-- Flash Messages -->
      <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
        <div
          id="flash"
          phx-hook="AutoDismiss"
          class="bg-blue-100 border border-blue-300 text-blue-700 px-4 py-2 rounded shadow transition-opacity duration-500"
        >
          {msg}
        </div>
      <% end %> --%>

      <GameBoard.game_board
        form={@form}
        hand={@hand}
        score={@score}
        wager={@wager}
        state={@state}
        all_in={@all_in}
      />
      <Component.rules />

      <LiveComponent.score_submit
        form={@form}
        game_id={5}
        score={@highest_score}
        current_user={@current_user}
      />
      <style>
        input[type=number]::-webkit-inner-spin-button,
        input[type=number]::-webkit-outer-spin-button {
          -webkit-appearance: none;
          margin: 0;
        }
        input[type=number] {
          -moz-appearance: textfield;
        }
      </style>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    default = PokerForm.default_values()

    socket =
      socket
      |> assign(default)

    {:ok, socket}
  end

  def handle_event("new", params, socket) do
    {hand, cards} =
      Helper.cards()
      |> Helper.shuffle()
      |> Helper.choose_5()

    [new_score, new_bet, wager] =
      if socket.assigns.all_in do
        [0, socket.assigns.bet, 0]
      else
        wager = String.to_integer(params["wager"])
        [socket.assigns.score - wager, wager, 10]
      end

    {:ok, valid} =
      PokerForm.merge_assigns(socket.assigns, %{
        bet: new_bet,
        cards: cards,
        hand: hand,
        highest_score: max(socket.assigns.score, socket.assigns.highest_score),
        state: "dealt",
        score: new_score,
        wager: wager
      })

    {:noreply, assign(socket, valid)}
  end

  def handle_event("advance", params, socket) do
    case socket.assigns.state do
      "dealt" ->
        wager = params["wager"]

        [new_hand, cards] = new_hand(params, socket)

        {:ok, valid} =
          PokerForm.merge_assigns(socket.assigns, %{
            hand: new_hand,
            cards: cards,
            score: socket.assigns.score - String.to_integer(wager),
            state: "final",
            bet: socket.assigns.bet + String.to_integer(wager),
            wager: 0
          })

        {:noreply, assign(socket, valid)}

      "final" ->
        {:ok, valid} =
          case Helper.classify(socket.assigns.hand) do
            {:high_card, _rank} ->
              PokerForm.merge_assigns(
                socket.assigns,
                %{
                  state: "reset",
                  all_in: false
                }
              )

            {:one_pair, [rank]} ->
              if rank >= 11 do
                PokerForm.merge_assigns(
                  socket.assigns,
                  %{
                    score: socket.assigns.score + socket.assigns.bet * 2,
                    state: "reset",
                    all_in: false
                  }
                )
              else
                PokerForm.merge_assigns(
                  socket.assigns,
                  %{
                    state: "reset",
                    all_in: false
                  }
                )
              end

            {_hand, _rank_suit} ->
              PokerForm.merge_assigns(
                socket.assigns,
                %{
                  score: socket.assigns.score + socket.assigns.bet * 2,
                  state: "reset",
                  all_in: false
                }
              )
          end

        {:noreply, assign(socket, valid)}
    end
  end

  def handle_event("all-in", _params, socket) do
    valid = %{
      bet: socket.assigns.bet + socket.assigns.score,
      all_in: true,
      score: 0
    }

    {:noreply, assign(socket, valid)}
  end

  def handle_event("reset", _params, socket) do
    {:ok, reset_assigns} =
      PokerForm.merge_assigns(socket.assigns, %{
        score: 100,
        bet: 0,
        hand: [],
        cards: [],
        wager: 10,
        state: "initial",
        all_in: false
      })

    {:noreply, assign(socket, reset_assigns)}
  end

  def handle_event("increase_wager", _params, %{assigns: %{all_in: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("decrease_wager", _params, %{assigns: %{all_in: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("increase_wager", _params, socket) do
    new_wager = min(socket.assigns.wager + 10, socket.assigns.score)

    all_in = new_wager == socket.assigns.score

    {:noreply, assign(socket, wager: new_wager, all_in: all_in)}
  end

  def handle_event("decrease_wager", _params, socket) do
    new_wager = max(socket.assigns.wager - 10, 10)

    all_in = new_wager == socket.assigns.score

    {:noreply, assign(socket, wager: new_wager, all_in: all_in)}
  end

  def handle_event("exit", params, socket) do
    ScoreHandler.save_score(socket, params)
  end

  def rotate_value(current, direction \\ :forward) do
    case Enum.find_index(@all_in_list, &(&1 == current)) do
      nil ->
        {:error, :not_found}

      index ->
        offset =
          case direction do
            :forward -> 1
            :backward -> -1
          end

        next_index = rem(index + offset, length(@all_in_list))
        next_index = if next_index < 0, do: next_index + length(@all_in_list), else: next_index
        Enum.at(@all_in_list, next_index)
    end
  end

  defp new_hand(params, socket) do
    raw_cards =
      Map.get(params, "replace", [])

    number_of_cards =
      length(raw_cards)

    selected_cards = selected_cards(raw_cards)

    new_hand = Helper.remove_cards(selected_cards, socket.assigns.hand)
    Helper.choose(socket.assigns.cards, new_hand, number_of_cards)
  end

  defp selected_cards([]), do: []

  defp selected_cards(raw_cards) do
    Enum.map(raw_cards, fn string ->
      [rank, suit] = String.split(string, ":")
      {String.to_integer(rank), suit}
    end)
  end

  def parse_card_param(param) do
    [rank, suit] = String.split(param, ":")
    {rank, suit}
  end
end
