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

        <.wager wager={@wager} score={@score} state={@state} all_in={@all_in} form={@form} />
      </.form>
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
        <div class="flex items-center gap-2 justify-center flex-wrap">
          <%= if @all_in do %>
            <.wager_input score={@score} wager={@wager} />
          <% else %>
            <label for="wager" class="font-semibold mr-2">Wager</label>

            <.action_button
              type="button"
              phx_click="decrease_wager"
              class="px-3 py-1 bg-gray-300 rounded hover:bg-gray-400 transition"
            >
              -10
            </.action_button>

            <.wager_input score={@score} wager={@wager} />

            <.action_button
              type="button"
              phx_click="increase_wager"
              class="px-3 py-1 bg-gray-300 rounded hover:bg-gray-400 transition"
            >
              +10
            </.action_button>

            <.action_button
              type="button"
              phx_click="all-in"
              class="px-3 py-1 bg-gray-300 rounded hover:bg-gray-400 transition"
            >
              All-In
            </.action_button>
          <% end %>
        </div>

        <button class="w-full bg-blue-500 hover:bg-blue-800 text-white font-semibold py-2 rounded">
          Deal Cards
        </button>
        """

      "dealt" ->
        ~H"""
        <div class="flex items-center gap-2 justify-center flex-wrap">
          <.wager_input score={@score} wager={@wager} />
        </div>

        <button class="w-full bg-blue-500 hover:bg-blue-800text-white font-semibold py-2 rounded">
          Replace Selected Cards
        </button>
        """

      "final" ->
        ~H"""
        <div class="flex items-center gap-2 justify-center flex-wrap">
          <.wager_input score={@score} wager={@wager} />
        </div>

        <button class="w-full bg-blue-500 hover:bg-blue-800text-white font-semibold py-2 rounded">
          Resolve
        </button>
        """

      "reset" ->
        if score == 0 do
          ~H"""
          <div class="flex items-center gap-2 justify-center flex-wrap invisible">
            <.wager_input score={@score} wager={@wager} />
          </div>
          <.action_button
            type="button"
            phx_click="reset"
            class="w-full bg-red-500 hover:bg-red-800text-white font-semibold py-2 rounded"
          >
            Reset Game
          </.action_button>
          """
        else
          ~H"""
          <div class="flex items-center gap-2 justify-center flex-wrap invisible">
            <.wager_input score={@score} wager={@wager} />
          </div>
          <.action_button
            type="button"
            phx_click="new-hand"
            class="w-full bg-blue-500 hover:bg-blue-800text-white font-semibold py-2 rounded"
          >
            New Hand
          </.action_button>
          """
        end
    end
  end

  attr(:wager, :integer, required: true)
  attr(:score, :integer, required: true)

  defp wager_input(assigns) do
    ~H"""
    <input
      id="wager"
      name="wager"
      type="number"
      value={@wager}
      min={10}
      max={@score}
      readonly
      class="w-20 text-center border rounded bg-white cursor-default"
    />
    """
  end

  attr(:phx_click, :string, default: nil)
  attr(:type, :string, default: "button")
  attr(:class, :string, default: "bg-gray-300 hover:bg-gray-400 text-white font-semibold")
  slot(:inner_block, required: true)

  defp action_button(assigns) do
    ~H"""
    <button type={@type} class={"#{@class} px-3 py-1 rounded transition"} phx-click={@phx_click}>
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
