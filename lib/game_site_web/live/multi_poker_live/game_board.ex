defmodule GameSiteWeb.MultiPokerLive.GameBoard do
  use GameSiteWeb, :live_view
  use Phoenix.Component

  attr(:phase, :atom, required: true)
  attr(:current_player_turn, :integer, required: false, default: nil)
  attr(:pot, :integer, required: true)
  attr(:dealer_player_id, :integer, required: false, default: nil)
  attr(:current_round_max_bet, :integer, required: true)
  attr(:winning_hand, :map, required: false, default: nil)

  def score_board(assigns) do
    ~H"""
    <section class="bg-white/5 border border-gray-800 rounded-lg px-3 py-2">
      <div class="flex flex-wrap items-center justify-between gap-3 text-sm">
        <div>
          <span class="text-gray-400 text-xs">Phase</span>
          <span class="ml-1 font-medium text-white">{format_phase(@phase)}</span>
        </div>

        <div>
          <span class="text-gray-400 text-xs">Pot</span>
          <span class="ml-1 font-medium text-white">{@pot}</span>
        </div>

        <div>
          <span class="text-gray-400 text-xs">Max Bet</span>
          <span class="ml-1 font-medium text-white">{@current_round_max_bet}</span>
        </div>
      </div>
    </section>
    """
  end

  attr(:players, :map, required: true)
  attr(:current_player_turn, :integer, required: true)
  attr(:community_cards, :list, required: true)
  attr(:current_viewer_id, :string, required: true)
  attr(:phase, :atom, required: true)
  attr(:winning_player_id, :integer, required: false, default: nil)
  attr(:dealer_player_id, :integer, required: false, default: nil)

  def game_table(assigns) do
    ~H"""
    <div class="space-y-3 sm:space-y-4">
      <div class="rounded-lg border border-gray-800 bg-black/40 p-2 sm:p-3 shadow-sm">
        <.community_cards community_cards={@community_cards} />
      </div>

      <div class="grid grid-cols-2 gap-3 sm:grid-cols-2 lg:grid-cols-1">
        <%= for {_id, player} <- @players do %>
          <.player_hand
            player_id={player.player_id}
            player_hand={player.hand}
            current_player_turn={@current_player_turn}
            show_hand={
              player.viewer_id == @current_viewer_id or
                @phase == :showdown or
                not is_nil(@winning_player_id)
            }
            chips={player.chips}
            current_bet={player.current_bet}
            folded?={player.folded?}
            ready?={player.ready?}
            winning_player_id={@winning_player_id}
            dealer_player_id={@dealer_player_id}
            is_current_viewer={player.viewer_id == @current_viewer_id}
          />
        <% end %>
      </div>
    </div>
    """
  end

  attr(:player_id, :integer, required: true)
  attr(:player_hand, :list, required: true)
  attr(:current_player_turn, :integer, required: false, default: nil)
  attr(:show_hand, :boolean, required: true)
  attr(:chips, :integer, required: true)
  attr(:current_bet, :integer, required: true)
  attr(:folded?, :boolean, required: true)
  attr(:ready?, :boolean, required: true)
  attr(:winning_player_id, :integer, required: false, default: nil)
  attr(:dealer_player_id, :integer, required: false, default: nil)
  attr(:is_current_viewer, :boolean, required: true)

  def player_hand(assigns) do
    ~H"""
    <div class={player_border_class(assigns)}>
      <div class="flex flex-col gap-2">
        <div class="flex flex-wrap items-center gap-1">
          <%= if @is_current_viewer do %>
            <span class="inline-flex items-center rounded-full bg-indigo-500/15 px-2 py-0.5 text-[11px] font-medium text-indigo-400">
              You
            </span>
          <% end %>

          <%= if @player_id == @dealer_player_id do %>
            <span class="inline-flex items-center rounded-full bg-blue-500/15 px-2 py-0.5 text-[11px] font-medium text-blue-400">
              Dealer
            </span>
          <% end %>

          <%= if @player_id == @current_player_turn do %>
            <span class="inline-flex items-center rounded-full bg-green-500/15 px-2 py-0.5 text-[11px] font-medium text-green-400">
              Turn
            </span>
          <% end %>

          <%= if @folded? do %>
            <span class="inline-flex items-center rounded-full bg-red-500/15 px-2 py-0.5 text-[11px] font-medium text-red-400">
              Folded
            </span>
          <% end %>

          <%= if @ready? do %>
            <span class="inline-flex items-center rounded-full bg-emerald-500/15 px-2 py-0.5 text-[11px] font-medium text-emerald-400">
              Ready
            </span>
          <% end %>
        </div>

        <div class="flex items-start justify-between gap-2">
          <div class="flex-1 overflow-x-auto">
            <.card_row cards={@player_hand} total_slots={2} reveal?={@show_hand} />
          </div>

          <div class="shrink-0 rounded-md border border-zinc-700 px-2 py-1 text-right min-w-[60px]">
            <div class="text-[9px] text-zinc-500 leading-none">CHIPS</div>
            <div class="text-sm font-semibold text-white leading-tight">{@chips}</div>

            <div class="mt-1 text-[9px] text-zinc-500 leading-none">BET</div>
            <div class="text-sm font-semibold text-white leading-tight">{@current_bet}</div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:community_cards, :list, required: true)

  def community_cards(assigns) do
    ~H"""
    <div class="flex items-center justify-center overflow-x-auto leading-none">
      <.card_row cards={@community_cards} total_slots={5} reveal?={true} />
    </div>
    """
  end

  attr(:cards, :list, required: true)
  attr(:total_slots, :integer, required: true)
  attr(:reveal?, :boolean, required: true)

  def card_row(assigns) do
    ~H"""
    <div class="flex gap-2 sm:gap-3 overflow-x-auto">
      <%= for card <- fill_cards(@cards, @total_slots) do %>
        <div class="flex flex-col items-center shrink-0">
          <%= cond do %>
            <% card && @reveal? -> %>
              <img
                src={card_image_url(card)}
                alt={card_to_string(card)}
                class="w-12 h-16 sm:w-16 sm:h-24 md:w-20 md:h-28 border rounded shadow transition"
              />
            <% true -> %>
              <img
                src={card_back()}
                alt="Hidden card"
                class="w-12 h-16 sm:w-16 sm:h-24 md:w-20 md:h-28 border rounded shadow transition"
              />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:room_status, :atom, required: true)
  attr(:action_state, :atom, required: true)
  attr(:player_chips, :integer, required: true)
  attr(:player_current_bet, :integer, required: true)
  attr(:bet_amount, :integer, required: false, default: 0)

  def player_actions(assigns) do
    ~H"""
    <%= if @room_status == :playing do %>
      <.player_controls
        player_chips={@player_chips}
        player_current_bet={@player_current_bet}
        bet_amount={@bet_amount}
        disabled={@action_state != :your_turn}
      />
    <% end %>
    """
  end

  attr(:disabled, :boolean, required: true)
  attr(:bet_amount, :integer, required: false, default: 0)
  attr(:player_chips, :integer, required: true)
  attr(:player_current_bet, :integer, required: true)

  def player_controls(assigns) do
    ~H"""
    <section class="rounded-lg border border-zinc-800 bg-zinc-950/80 p-3 space-y-3">
      <form phx-submit="player-bet" class="space-y-3">
        <div class="flex items-end gap-2">
          <div class="flex-1">
            <label for="bet_amount" class="mb-1 block text-xs font-medium text-zinc-400">
              Bet Amount
            </label>
            <input
              id="bet_amount"
              name="bet_amount"
              type="number"
              min={@bet_amount}
              max={@player_chips}
              value={@bet_amount}
              disabled={@disabled}
              class={[
                "w-full rounded-md border px-3 py-2 text-sm bg-zinc-900 text-zinc-100 focus:outline-none",
                "border-zinc-700 focus:ring-2 focus:ring-blue-500",
                @disabled && "bg-zinc-800 text-zinc-500 cursor-not-allowed opacity-70"
              ]}
            />
          </div>

          <button
            type="submit"
            disabled={@disabled}
            class={button_class("bg-blue-600 hover:bg-blue-700", @disabled)}
          >
            Bet
          </button>
        </div>

        <div class="grid grid-cols-3 gap-2 sm:grid-cols-4">
          <button
            type="button"
            phx-click="player-fold"
            disabled={@disabled}
            class={button_class("bg-red-600 hover:bg-red-700", @disabled)}
          >
            Fold
          </button>

          <% check_disabled = @disabled or @bet_amount > 0 %>
          <button
            type="button"
            phx-click="player-check"
            disabled={check_disabled}
            class={button_class("bg-zinc-700 hover:bg-zinc-600", check_disabled)}
          >
            Check
          </button>

          <button
            type="button"
            phx-click="player-all-in"
            disabled={@disabled}
            class={button_class("bg-yellow-600 hover:bg-yellow-700", @disabled)}
          >
            All In
          </button>

          <div class="hidden sm:block"></div>
        </div>
      </form>
    </section>
    """
  end

  attr(:viewer_state, :map, required: true)
  attr(:room_status, :atom, required: true)
  attr(:room_full, :boolean, required: true)

  def join_game(assigns) do
    ~H"""
    <div class="flex justify-center">
      <%= if @room_status == :waiting and @viewer_state.action_state == :not_joined and not @room_full do %>
        <button
          phx-click="join-game"
          class="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow hover:bg-blue-700 transition"
        >
          Join Game
        </button>
      <% end %>

      <%= if @viewer_state.action_state != :not_joined and @room_status == :waiting do %>
        <button
          phx-click="leave-game"
          class="rounded-md bg-red-600 px-4 py-2 text-sm font-medium text-white shadow hover:bg-red-700 transition"
        >
          Leave Game
        </button>
      <% end %>
    </div>
    """
  end

  attr(:game_state, :atom, required: true)
  attr(:viewer_state, :map, required: true)

  def player_ready(assigns) do
    ~H"""
    <div class="flex justify-center">
      <%= if @game_state == :waiting and
            @viewer_state.action_state != :not_joined and
            not @viewer_state.ready? and
            not @viewer_state.busted? do %>
        <button
          phx-click="player-ready"
          class="rounded-md bg-emerald-600 px-4 py-2 text-sm font-medium text-white shadow hover:bg-emerald-700 transition"
        >
          Ready
        </button>
      <% end %>
    </div>
    """
  end

  defp player_border_class(assigns) do
    base = "rounded-xl border bg-white p-3 sm:p-4 shadow-sm"

    cond do
      assigns.player_id == assigns.winning_player_id ->
        "#{base} border-green-600 ring-2 ring-green-300"

      assigns.ready? ->
        "#{base} border-red-500"

      assigns.player_id == assigns.current_player_turn ->
        "#{base} border-green-500 ring-2 ring-green-200"

      true ->
        "#{base} border-gray-200"
    end
  end

  defp button_class(base, true) do
    "#{base} opacity-50 cursor-not-allowed pointer-events-none rounded-lg px-4 py-2 text-white font-medium shadow"
  end

  defp button_class(base, false) do
    "#{base} rounded-lg px-4 py-2 text-white font-medium shadow transition"
  end

  defp format_phase(phase) do
    phase
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp card_image_url({rank, suit}) do
    "/images/cards/#{suit}_#{rank}.png"
  end

  defp card_to_string({rank, suit}), do: "#{rank_to_string(rank)} of #{suit_symbol(suit)}"

  defp card_back(), do: "/images/logo.svg"

  defp fill_cards(cards, total_slots) do
    cards
    |> Enum.take(total_slots)
    |> then(fn trimmed ->
      trimmed ++ List.duplicate(nil, total_slots - length(trimmed))
    end)
  end

  defp suit_symbol("hearts"), do: "♥"
  defp suit_symbol("diamonds"), do: "♦"
  defp suit_symbol("clubs"), do: "♣"
  defp suit_symbol("spades"), do: "♠"

  defp rank_to_string(11), do: "J"
  defp rank_to_string(12), do: "Q"
  defp rank_to_string(13), do: "K"
  defp rank_to_string(14), do: "A"
  defp rank_to_string(n), do: Integer.to_string(n)
end
