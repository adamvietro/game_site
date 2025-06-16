defmodule GameSiteWeb.PokerLive do
  use GameSiteWeb, :live_view

  import GameSiteWeb.LoginHelpers
  alias GameSiteWeb.PokerForm
  alias GameSite.Scores
  alias GameSiteWeb.PokerHelpers, as: Helper

  @all_in_list ["initial", "dealt", "final"]

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-4 space-y-8">

    <!-- Game Info and Scores -->
      <section class="bg-gray-50 rounded p-4 shadow">
        <h2 class="text-xl font-semibold mb-2">Poker Game Overview</h2>
        <ul class="list-disc list-inside mt-2 space-y-1 text-gray-700">
          <li>Draw 5 cards and choose which ones to keep.</li>
          <li>Adjust your wager before drawing cards and again after dealing.</li>
          <li>Going "all-in" means you cannot reduce your wager afterwards.</li>
          <li>Your goal is to achieve the highest score possible.</li>
          <li>If your score reaches 0, the game resets but keeps track of your highest score.</li>
        </ul>

        <div class="mt-4 grid grid-cols-3 gap-4 text-center font-semibold text-gray-800">
          <div>
            <div class="text-sm text-gray-500">Highest Score</div>
            <div>{@highest_score}</div>
          </div>
          <div>
            <div class="text-sm text-gray-500">Current Score</div>
            <div>{@score}</div>
          </div>
          <div>
            <div class="text-sm text-gray-500">Current Bet</div>
            <div>{@bet}</div>
          </div>
        </div>
      </section>

    <!-- Flash Messages -->
      <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
        <div
          id="flash"
          phx-hook="AutoDismiss"
          class="bg-blue-100 border border-blue-300 text-blue-700 px-4 py-2 rounded shadow transition-opacity duration-500"
        >
          {msg}
        </div>
      <% end %>

    <!-- Card Selection and Actions -->
      <section class="bg-white rounded p-4 shadow space-y-6">
        <.form for={@form} phx-submit="advance" class="space-y-6">
          <div class="flex flex-wrap justify-center gap-4 min-h-[7rem] md:min-h-[8rem]">
            <%= for card <- (@hand ++ List.duplicate(nil, 5 - length(@hand))) |> Enum.take(5) do %>
              <div class="flex flex-col items-center">
                <%= if card do %>
                  <label class="cursor-pointer flex flex-col items-center">
                    <input
                      type="checkbox"
                      name="replace[]"
                      value={card_to_param(card)}
                      class="hidden peer"
                    />
                    <img
                      src={card_image_url(card)}
                      alt={card_to_string(card)}
                      class="w-20 h-28 border rounded shadow peer-checked:ring-4 peer-checked:ring-blue-500 transition"
                    />
                    <div class="mt-1 text-sm text-center peer-checked:text-blue-600 transition-colors">
                      {card_to_string(card)}
                    </div>
                  </label>
                <% else %>
                  <!-- Placeholder box same size as card -->
                  <div class="w-20 h-28 border rounded bg-gray-100"></div>
                  <div class="mt-1 text-sm text-center text-gray-400">Waiting...</div>
                <% end %>
              </div>
            <% end %>
          </div>

    <!-- Your buttons and wager inputs unchanged below -->
          <div>
            <%= cond do %>
              <% @state == "reset" and @score == 0 -> %>
                <button
                  type="button"
                  phx-click="reset"
                  class="w-full md:w-auto block md:inline-block bg-red-600 hover:bg-red-700 text-white font-semibold py-2 px-6 rounded transition"
                >
                  Reset Game
                </button>
              <% @state == "final" -> %>
                <button
                  type="submit"
                  class="w-full md:w-auto block md:inline-block bg-green-600 hover:bg-green-700 text-white font-semibold py-2 px-6 rounded transition"
                >
                  Showdown
                </button>
              <% @state == "dealt" -> %>
                <div class="flex flex-col md:flex-row items-center justify-center gap-4 md:gap-6">
                  <div class="flex items-center gap-2">
                    <%= if @all_in do %>
                      <input type="hidden" name="wager" value="0" />
                    <% else %>
                      <label for="wager" class="font-semibold">Wager</label>

                      <button
                        type="button"
                        phx-click="decrease_wager"
                        class="px-3 py-1 bg-gray-300 rounded hover:bg-gray-400 transition"
                      >
                        -10
                      </button>

                      <input
                        id="wager"
                        name="wager"
                        type="number"
                        value={@wager}
                        max={@score}
                        readonly
                        class="w-20 text-center border rounded bg-white cursor-default"
                      />

                      <button
                        type="button"
                        phx-click="increase_wager"
                        class="px-3 py-1 bg-gray-300 rounded hover:bg-gray-400 transition"
                      >
                        +10
                      </button>

                      <button
                        type="button"
                        phx-click="all-in"
                        class="px-3 py-1 bg-gray-300 rounded hover:bg-gray-400 transition"
                      >
                        All-In
                      </button>
                    <% end %>
                  </div>

                  <button
                    type="submit"
                    class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-6 rounded transition"
                  >
                    Replace Selected Cards
                  </button>
                </div>
              <% true -> %>
                <!-- No button for other states -->
            <% end %>
          </div>
        </.form>
        <!-- New Hand Form -->
        <%= if @state in ["initial", "reset"] and not (@state == "reset" and @score == 0) do %>
          <section class="bg-gray-50 rounded p-4 shadow max-w-md mx-auto">
            <.simple_form id="new-form" for={@form} phx-submit="new" class="space-y-4">
              <div class="flex items-center gap-2 justify-center flex-wrap">
                <%= if @all_in do %>
                  <input type="hidden" name="wager" value="0" />
                <% else %>
                  <label for="wager" class="font-semibold mr-2">Wager</label>

                  <button
                    type="button"
                    phx-click="decrease_wager"
                    class="px-3 py-1 bg-gray-300 rounded hover:bg-gray-400 transition"
                  >
                    -10
                  </button>

                  <input
                    id="wager"
                    name="wager"
                    type="number"
                    value={@wager}
                    min="10"
                    max={@score}
                    readonly
                    class="w-20 text-center border rounded bg-white cursor-default"
                  />

                  <button
                    type="button"
                    phx-click="increase_wager"
                    class="px-3 py-1 bg-gray-300 rounded hover:bg-gray-400 transition"
                  >
                    +10
                  </button>

                  <button
                    type="button"
                    phx-click="all-in"
                    class="px-3 py-1 bg-gray-300 rounded hover:bg-gray-400 transition"
                  >
                    All-In
                  </button>
                <% end %>
              </div>

              <:actions>
                <.button class="w-full bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 rounded">
                  New Hand
                </.button>
              </:actions>
            </.simple_form>
          </section>
        <% end %>
      </section>

    <!-- Rules Section -->
      <section class="bg-white rounded p-4 shadow max-w-md mx-auto">
        <h3 class="text-lg font-semibold mb-2">Rules</h3>
        <ul class="list-disc list-inside space-y-1 text-gray-700">
          <li>Minimum wager is 10.</li>
          <li>Maximum wager is your current score (money).</li>
          <li>You can reset the game only if your score reaches 0.</li>
          <li>
            You can increase your wager only before the cards are dealt and after dealing, not during other phases.
          </li>
        </ul>

        <p class="mt-3 text-sm text-gray-600 font-semibold">
          <strong>Note:</strong>
          Please be cautious when increasing your wager, especially when going all-in!
        </p>

        <p class="mt-4 text-xs italic text-gray-400">
          #TODO: Fix CSS styling for a better experience.
        </p>
      </section>

    <!-- Exit and Save Form -->
      <%= if not logged_in?(@socket.assigns) do %>
        <br /> <br />If you want to submit your score please make an
        <a
          href="/users/register"
          style="cursor: pointer; text-decoration: none; color: blue;"
          onmouseover="this.style.textDecoration='underline'; this.style.color='red';"
          onmouseout="this.style.textDecoration='none'; this.style.color='blue';"
        >
          account
        </a>
      <% end %>

      <%= if logged_in?(@socket.assigns) do %>
        <section class="max-w-md mx-auto">
          <.simple_form
            id="exit-form"
            for={@form}
            phx-submit="exit"
            name="exit-form"
            class="space-y-4"
          >
            <.input type="hidden" field={@form[:user_id]} value={@current_user.id} name="user_id" />
            <.input type="hidden" field={@form[:game_id]} value={5} name="game_id" />
            <.input type="hidden" field={@form[:score]} value={@highest_score} name="score" />
            <:actions>
              <.button class="w-full bg-gray-700 hover:bg-gray-800 text-white py-2 rounded">
                Exit and Save Score
              </.button>
            </:actions>
          </.simple_form>
        </section>
      <% end %>

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
      # state: rotate_value(socket.assigns.state),
      score: 0
    }

    {:noreply, assign(socket, valid)}
  end

  def handle_event("reset", _params, socket) do
    {:ok, reset_assigns} =
      PokerForm.merge_assigns(socket.assigns, %{
        # or whatever your default starting score is
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
    save_score(socket, :new, params)
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

  defp card_to_string({rank, suit}), do: "#{rank} of #{String.capitalize(suit)}"

  defp card_to_param({rank, suit}), do: "#{rank}:#{suit}"

  def parse_card_param(param) do
    [rank, suit] = String.split(param, ":")
    {rank, suit}
  end

  defp card_image_url({rank, suit}) do
    "/images/cards/#{suit}_#{rank}.png"
  end

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
