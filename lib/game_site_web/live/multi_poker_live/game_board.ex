defmodule GameSiteWeb.MultiPokerLive.GameBoard do
  use Phoenix.Component
  alias GameSite.MultiPoker.{Room, Player}

  attr(:phase, :atom, required: true)
  attr(:current_player_turn, :integer, required: true)
  attr(:pot, :integer, required: true)
  attr(:dealer_player_id, :integer, required: true)

  def score_board(assigns) do
    ~H"""
    <section class="bg-white shadow-md rounded-xl p-4 border border-gray-200">
      <h2 class="text-lg font-semibold mb-4 text-center">Table Info</h2>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div class="bg-gray-50 rounded-lg p-3">
          <p class="text-sm text-gray-500">Phase</p>
          <p class="text-base font-medium">{format_phase(@phase)}</p>
        </div>

        <div class="bg-gray-50 rounded-lg p-3">
          <p class="text-sm text-gray-500">Pot</p>
          <p class="text-base font-medium">{@pot}</p>
        </div>

        <div class="bg-gray-50 rounded-lg p-3">
          <p class="text-sm text-gray-500">Current Turn</p>
          <p class="text-base font-medium">
            {player_label(@current_player_turn)}
          </p>
        </div>

        <div class="bg-gray-50 rounded-lg p-3">
          <p class="text-sm text-gray-500">Dealer</p>
          <p class="text-base font-medium">
            {player_label(@dealer_player_id)}
          </p>
        </div>
      </div>
    </section>
    """
  end

  attr(:players, :map, required: true)
  attr(:current_player, :integer, required: false, default: nil)
  attr(:community_cards, :list, required: true)
  attr(:current_player_id, :integer, required: true)

  def game_table(assigns) do
    ~H"""
    <div class="space-y-6">
      <%= for {_id, player} <- @players do %>
        <.player_hand
          player_id={player.player_id}
          player_hand={player.hand}
          current_player={@current_player}
          show_hand={player.player_id == @current_player}
        />
      <% end %>

      <.community_cards community_cards={@community_cards} />
    </div>
    """
  end

  attr(:player_id, :integer, required: true)
  attr(:player_hand, :list, required: true)
  attr(:current_player, :integer, required: false, default: nil)
  attr(:show_hand, :boolean, required: true)

  def player_hand(assigns) do
    ~H"""
    <div class="space-y-2">
      <div class="text-center font-medium">
        Player {@player_id}
        <%= if @player_id == @current_player do %>
          <span class="ml-2 text-green-600">(Current Turn)</span>
        <% end %>
      </div>

      <.card_row cards={@player_hand} total_slots={2} reveal?={@show_hand} />
    </div>
    """
  end

  attr(:community_cards, :list, required: true)

  def community_cards(assigns) do
    ~H"""
    <div class="space-y-2">
      <div class="text-center font-medium">Community Cards</div>
      <.card_row cards={@community_cards} total_slots={5} reveal?={true} />
    </div>
    """
  end

  attr(:cards, :list, required: true)
  attr(:total_slots, :integer, required: true)
  attr(:reveal?, :boolean, required: true)

  def card_row(assigns) do
    ~H"""
    <div class="flex flex-wrap justify-center gap-4 min-h-[7rem] md:min-h-[8rem]">
      <%= for card <- fill_cards(@cards, @total_slots) do %>
        <div class="flex flex-col items-center">
          <%= cond do %>
            <% card && @reveal? -> %>
              <img
                src={card_image_url(card)}
                alt={card_to_string(card)}
                class="w-20 h-28 border rounded shadow transition"
              />
              <div class="mt-1 text-sm text-center">
                {card_to_string(card)}
              </div>
            <% true -> %>
              <img
                src={card_back()}
                alt="Hidden card"
                class="w-20 h-28 border rounded shadow transition"
              />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp format_phase(phase) do
    phase
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp player_label(nil), do: "—"
  defp player_label(player_id), do: "Player #{player_id}"

  defp card_image_url({rank, suit}) do
    "/images/cards/#{suit}_#{rank}.png"
  end

  defp card_to_string({rank, suit}), do: "#{rank} of #{String.capitalize(suit)}"

  defp card_back(), do: "/images/logo.svg"

  defp fill_cards(cards, total_slots) do
    cards
    |> Enum.take(total_slots)
    |> then(fn trimmed ->
      trimmed ++ List.duplicate(nil, total_slots - length(trimmed))
    end)
  end
end
