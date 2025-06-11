defmodule GameSiteWeb.PokerLive do
  use GameSiteWeb, :live_view
  alias GameSiteWeb.PokerForm
  alias GameSite.Scores
  alias GameSiteWeb.PokerHelpers, as: Helper

  def render(assigns) do
    ~H"""
    <p>Highest Score: {@highest_score}</p>
    <p>Score: {@score}</p>
    <%!-- <p>Number of cards left: {"#{length(@cards)}"}</p> --%>

    <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
      <div id="flash" phx-hook="AutoDismiss" class="flash-info transition-opacity duration-500">
        {msg}
      </div>
    <% end %>
    <div class="display-flex">
      <%= if @hand != [] do %>
        <.form for={@form} phx-submit="advance">
          <div class="flex gap-4">
            <%= for card <- @hand do %>
              <div class="flex flex-col items-center">
                <label>
                  <input type="checkbox" name="replace[]" value={card_to_param(card)} />
                  <div class="border p-2 mt-1">
                    {card_to_string(card)}
                  </div>
                </label>
              </div>
            <% end %>
          </div>
          <.input field={@form[:wager]} label="wager" name="wager" value={@wager} />
          <button type="submit" class="mt-4 bg-blue-500 text-white px-4 py-2 rounded">
            Replace Cards/Showdown
          </button>
        </.form>
      <% end %>
      <%= if @state == "initial" or "reset" do %>
        <.simple_form id="new-form" for={@form} phx-submit="new">
          <:actions>
            <.button class="mt-4 bg-blue-500 text-white px-4 py-2 rounded">New</.button>
          </:actions>
        </.simple_form>
      <% end %>
    </div>
    <div>
      This is my Poker Game. You will be able to draw 5 cards and then choose which ones to
      keep. Before you draw cards, before you pick new cards you will be able to increase your wager.
      You want to get the highest score possible. IF any any point you run out of score(money)
      the game will reset but it will still keep track of your highest score. <br /><br />#TODO:
      <br />Fix CSS
    </div>

    <%!-- <.simple_form id="exit-form" for={@form} phx-submit="exit" name="exit-form">
      <.input type="hidden" field={@form[:user_id]} value={@current_user.id} name="exit-user.id" />
      <.input type="hidden" field={@form[:game_id]} value={5} name="exit-game.id" />
      <.input type="hidden" field={@form[:score]} value={@highest_score} name="exit-score" />
      <:actions>
        <.button>Exit and Save Score</.button>
      </:actions>
    </.simple_form> --%>
    """
  end

  def mount(_params, _session, socket) do
    default = PokerForm.default_values()

    socket =
      socket
      |> assign(default)

    {:ok, socket}
  end

  def handle_event("new", _, socket) do
    {hand, cards} =
      Helper.cards()
      |> Helper.shuffle()
      |> Helper.choose_5()

    valid =
      PokerForm.passed?(%{
        cards: cards,
        hand: hand,
        highest_score: max(socket.assigns.score, socket.assigns.highest_score),
        state: "dealt"
      })

    socket =
      socket
      |> assign(valid)

    {:noreply, socket}
  end

  def handle_event("advance", %{"wager" => wager} = params, socket) do
    raw_cards = Map.get(params, "replace", [])

    case socket.assigns.state do
      "dealt" ->
        number_of_cards = length(raw_cards)
        selected_cards = selected_cards(raw_cards)

        new_hand = Helper.remove_cards(selected_cards, socket.assigns.hand)
        [new_hand, cards] = Helper.choose(socket.assigns.cards, new_hand, number_of_cards)

        {:noreply,
         assign(socket,
           hand: new_hand,
           cards: cards,
           score: socket.assigns.score - String.to_integer(wager),
           state: "final",
           bet: socket.assigns.bet + String.to_integer(wager)
         )}

      "final" ->
        hand = socket.assigns.hand

        case Helper.classify(hand) do
          {:high_card, rank} ->
            # not a winner
            # keep the score the same
            # set state: "reset"
            #
            nil

          {:one_pair, rank} ->
            # winner if jack or higher if 11 or higher
            # keep the
            nil

          {hand, rank_suit} ->
            # do above for all the rest.
            nil
        end

        {:no_reply, socket}
    end
  end

  def handle_event("exit", params, socket) do
    save_score(socket, :new, params)
  end

  defp selected_cards([]), do: []

  defp selected_cards(raw_cards) do
    Enum.map(raw_cards, fn string ->
      [rank, suit] = String.split(string, ":")
      {String.to_integer(rank), suit}
    end)
  end

  defp card_to_string({rank, suit}), do: "#{rank} of #{String.capitalize(suit)}"

  @spec card_to_param({any(), any()}) :: nonempty_binary()
  defp card_to_param({rank, suit}), do: "#{rank}:#{suit}"

  defp save_score(socket, :new, score_params) do
    case Scores.create_score(score_params) do
      {:ok, score} ->
        notify_parent({:new, score})

        {:noreply,
         socket |> put_flash(:info, "Score created successfully") |> push_navigate(to: "/scores")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:duplicate, :already_exists} ->
        {:noreply,
         socket |> put_flash(:info, "No new High Score") |> push_navigate(to: "/scores")}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
