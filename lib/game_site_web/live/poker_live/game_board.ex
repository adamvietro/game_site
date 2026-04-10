defmodule GameSiteWeb.PokerLive.GameBoard do
  use GameSiteWeb, :live_view

  attr(:form, :map, required: true)
  attr(:hand, :map, required: true)
  attr(:score, :integer, required: true)
  attr(:wager, :integer, required: true)
  attr(:state, :atom, required: true)
  attr(:all_in, :atom, required: true)

  def game_board(assigns) do
    ~H"""
    <section class="bg-white rounded p-3 shadow space-y-4 sm:p-4 sm:space-y-6">
      <.form for={@form} phx-submit="advance" class="space-y-4 sm:space-y-6">
        <.hand hand={@hand} />
        <.wager wager={@wager} score={@score} state={@state} all_in={@all_in} form={@form} />
      </.form>
    </section>
    """
  end

  attr(:hand, :map, required: true)

  def hand(assigns) do
    ~H"""
    <div class="grid grid-cols-5 gap-2 justify-items-center min-h-[6rem] sm:min-h-[8rem] sm:gap-4">
      <%= for card <- (@hand ++ List.duplicate(nil, 5 - length(@hand))) |> Enum.take(5) do %>
        <div class="flex flex-col items-center">
          <%= if card do %>
            <label class="cursor-pointer flex flex-col items-center">
              <input
                type="checkbox"
                name="replace[]"
                value={card_to_param(card)}
                class="hidden card-checkbox"
              />

              <img
                src={card_image_url(card)}
                alt={card_to_string(card)}
                class="card-img w-12 h-16 sm:w-20 sm:h-28 border-2 border-gray-300 rounded shadow transition"
              />
            </label>
          <% else %>
            <div class="w-12 h-16 border-2 border-gray-200 rounded bg-gray-100 sm:w-20 sm:h-28"></div>
          <% end %>
        </div>
      <% end %>
    </div>

    <style>
      .card-checkbox:checked + .card-img {
        border-color: #3b82f6; /* blue */
        box-shadow: 0 0 0 2px rgba(59,130,246,0.5);
        transform: scale(1.05);
      }
    </style>
    """
  end

  attr(:wager, :integer, required: true)
  attr(:score, :integer, required: true)
  attr(:state, :string, required: true)
  attr(:all_in, :atom, required: true)
  attr(:form, :map, required: true)

  def wager(assigns) do
    ~H"""
    <div class={"flex items-center gap-1 justify-center flex-wrap #{invisible_class(@state)} sm:gap-2"}>
      <%= if @state == "initial" and not @all_in do %>
        <label for="wager" class="font-semibold mr-1 text-sm sm:mr-2 sm:text-base">Wager</label>

        <.action_button
          type="button"
          phx_click="decrease_wager"
          class="text-sm px-2 py-1 bg-gray-300 rounded hover:bg-gray-400 transition sm:px-3"
        >
          -10
        </.action_button>

        <.current_wager score={@score} wager={@wager} />

        <.action_button
          type="button"
          phx_click="increase_wager"
          class="text-sm px-2 py-1 bg-gray-300 rounded hover:bg-gray-400 transition sm:px-3"
        >
          +10
        </.action_button>

        <.action_button
          type="button"
          phx_click="all-in"
          class="text-sm px-2 py-1 bg-gray-300 rounded hover:bg-gray-400 transition sm:px-3"
        >
          All-In
        </.action_button>
      <% else %>
        <.current_wager score={@score} wager={@wager} />
      <% end %>
    </div>

    <%= case @state do %>
      <% "initial" -> %>
        <.btn>Deal Cards</.btn>
      <% "dealt" -> %>
        <.btn>Replace Selected Cards</.btn>
      <% "final" -> %>
        <.btn>Resolve</.btn>
      <% "reset" -> %>
        <.action_button
          type="button"
          phx_click={if @score == 0, do: "reset", else: "new-hand"}
          class={
            if @score == 0,
              do: "w-full bg-red-500 hover:bg-red-800 text-white font-semibold py-2 rounded",
              else: "w-full bg-blue-500 hover:bg-blue-800 text-white font-semibold py-2 rounded"
          }
        >
          {if @score == 0, do: "Reset Game", else: "New Hand"}
        </.action_button>
    <% end %>
    """
  end

  defp invisible_class("reset"), do: "invisible"
  defp invisible_class(_), do: ""

  attr(:wager, :integer, required: true)
  attr(:score, :integer, required: true)

  defp current_wager(assigns) do
    ~H"""
    <input
      id="wager"
      name="wager"
      type="number"
      value={@wager}
      min={10}
      max={@score}
      readonly
      class="w-16 text-center border rounded bg-white cursor-default text-sm sm:w-20"
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
    """
  end

  slot(:inner_block, required: true)

  defp btn(assigns) do
    ~H"""
    <button class="w-full bg-blue-500 hover:bg-blue-800 text-white font-semibold py-2 rounded">
      {render_slot(@inner_block)}
    </button>
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
