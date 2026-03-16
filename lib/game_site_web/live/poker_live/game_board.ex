defmodule GameSiteWeb.Live.PokerLive.GameBoard do
  use GameSiteWeb, :live_view

  attr(:form, :map, required: true)
  attr(:hand, :map, required: true)
  attr(:score, :integer, required: true)
  attr(:wager, :integer, required: true)
  attr(:state, :atom, required: true)
  attr(:all_in, :atom, required: true)

  def game_board(assigns) do
    ~H"""
    <section class="bg-white rounded p-4 shadow space-y-6">
      <.form for={@form} phx-submit="advance" class="space-y-6">
        <.hand hand={@hand} />
        
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
                Resolve
              </button>
            <% @state == "dealt" -> %>
              <div class="flex flex-col md:flex-row items-center justify-center gap-4 md:gap-6">
                <div class="flex items-center gap-2">
                  <%= if @all_in do %>
                    <input id="wager" name="wager" type="number" value={@wager} readonly />
                  <% else %>
                    <label for="wager" class="font-semibold">Wager</label>

                    <%!-- <button
                      type="button"
                      phx-click="decrease_wager"
                      class="px-3 py-1 bg-gray-300 rounded hover:bg-gray-400 transition"
                    >
                      -10
                    </button> --%>

                    <input
                      id="wager"
                      name="wager"
                      type="number"
                      value={@wager}
                      max={@score}
                      readonly
                      class="w-20 text-center border rounded bg-white cursor-default"
                    />

                    <%!-- <button
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
                    </button> --%>
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
    """
  end

  attr(:hand, :map, required: true)

  def hand(assigns) do
    ~H"""
    <div class="flex flex-wrap justify-center gap-4 min-h-[7rem] md:min-h-[8rem]">
      <%= for card <- (@hand ++ List.duplicate(nil, 5 - length(@hand))) |> Enum.take(5) do %>
        <div class="flex flex-col items-center">
          <%= if card do %>
            <label class="cursor-pointer flex flex-col items-center">
              <input type="checkbox" name="replace[]" value={card_to_param(card)} class="hidden peer" />
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
            <div class="w-20 h-28 border rounded bg-gray-100"></div>
            <div class="mt-1 text-sm text-center text-gray-400">Waiting...</div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:wager, :integer, required: true)
  attr(:score, :integer, required: true)
  attr(:state, :string, required: true)
  attr(:all_in, :atom, required: true)
  attr(:form, :map, required: true)

  def wager(assigns) do
    state = assigns.state
    score = assigns.score

    case state do
      "initial" ->
        ~H"""
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
            <.action_button class="w-full bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 rounded">
              New Hand
            </.action_button>
          </:actions>
        </.simple_form>
        """

      "dealt" ->
        ~H"""
        <.wager_input score={@score} wager={@wager} />

        <.action_button
          type="submit"
          class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-6 rounded transition"
        >
          Replace Selected Cards
        </.action_button>
        """

      "final" ->
        ~H"""
        <.wager_input score={@score} wager={@wager} />

        <.action_button
          type="submit"
          class="w-full md:w-auto block md:inline-block bg-green-600 hover:bg-green-700 text-white font-semibold py-2 px-6 rounded transition"
        >
          Resolve
        </.action_button>
        """

      "reset" ->
        if score == 0 do
          ~H"""
          <.action_button
            type="button"
            phx_click="reset"
            class="w-full md:w-auto block md:inline-block bg-red-600 hover:bg-red-700 text-white font-semibold py-2 px-6 rounded transition"
          >
            Reset Game
          </.action_button>
          """
        else
          ~H"""
          <.action_button
            type="button"
            phx_click="new-hand"
            class="w-full md:w-auto block md:inline-block bg-red-600 hover:bg-red-700 text-white font-semibold py-2 px-6 rounded transition"
          >
            Reset Game
          </.action_button>
          """
        end
    end
  end

  attr(:wager, :integer, required: true)
  attr(:score, :integer, required: true)
  attr(:min, :integer, default: 10)
  attr(:max, :integer)

  defp wager_input(assigns) do
    ~H"""
    <input
      id="wager"
      name="wager"
      type="number"
      value={@wager}
      min={@min}
      max={@max || @score}
      readonly
      class="w-20 text-center border rounded bg-white cursor-default"
    />
    """
  end

  attr(:phx_click, :string)
  attr(:type, :string, default: "button")
  attr(:class, :string, default: "bg-gray-300 hover:bg-gray-400 text-white font-semibold")
  slot(:inner_block, required: true)

  defp action_button(assigns) do
    ~H"""
    <button type={@type} phx-click={@phx_click} class={"#{@class} px-3 py-1 rounded transition"}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp card_image_url({rank, suit}) do
    "/images/cards/#{suit}_#{rank}.png"
  end

  defp card_to_string({rank, suit}), do: "#{rank} of #{String.capitalize(suit)}"

  defp card_to_param({rank, suit}), do: "#{rank}:#{suit}"
end
