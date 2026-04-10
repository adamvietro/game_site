defmodule GameSiteWeb.GuessingLive.Component do
  use GameSiteWeb, :live_view
  use Phoenix.Component

  attr(:form, :map, required: true)
  attr(:guessed_numbers, :any, required: true)

  def input_buttons(assigns) do
    ~H"""
    <div class="mx-auto mt-4 w-full max-w-md px-4 sm:px-0">
      <div class="grid grid-cols-3 gap-2 sm:grid-cols-4 md:grid-cols-5">
        <%= for guess <- 1..10 do %>
          <% id = "GuessButton#{guess}" %>
          <form phx-submit="answer" class="m-0">
            <input type="hidden" name="guess" value={guess} id={"guess_hidden_#{guess}"} />
            <input type="hidden" name="wager" id={"wager_hidden_#{guess}"} />

            <button
              type="submit"
              id={id}
              phx-hook="CopyBonus"
              disabled={MapSet.member?(@guessed_numbers, guess)}
              class={guess_button_class(@guessed_numbers, guess)}
            >
              {guess}
            </button>
          </form>
        <% end %>
      </div>
    </div>
    """
  end

  attr(:wager, :integer, required: true)
  attr(:score, :integer, required: true)
  attr(:form, :map, required: true)

  def wager(assigns) do
    ~H"""
    <div class="mx-auto mt-6 w-full max-w-md px-4 sm:px-0">
      <div class="min-h-[28px] flex items-center justify-center">
        <.error_message form={@form} />
      </div>

      <div class="flex items-end gap-2">
        <div class="flex-1">
          <input
            type="number"
            id="wager_input"
            name="wager_visible"
            min="1"
            value={@wager}
            max={@score}
            step="1"
            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          />
        </div>

        <button
          type="button"
          phx-click="set_max_wager"
          class="rounded-lg bg-blue-500 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-blue-600"
        >
          Max
        </button>
      </div>

      <p class="mt-2 text-xs text-gray-500">
        Max wager: {@score}
      </p>
    </div>
    """
  end

  attr(:form, :map, required: true)

  def error_message(assigns) do
    ~H"""
    <%= for {_field, {msg, meta}} <- @form.errors do %>
      <p class={
        case meta[:type] do
          :info -> "text-center text-sm font-medium text-green-600"
          :error -> "text-center text-sm font-medium text-red-600"
          _ -> "text-center text-sm font-medium text-gray-600"
        end
      }>
        {msg}
      </p>
    <% end %>
    """
  end

  defp guess_button_class(set, guess) do
    base = "w-full py-2 rounded-lg text-sm font-semibold"

    if MapSet.member?(set, guess) do
      base <> " bg-red-500 text-white opacity-80 cursor-not-allowed"
    else
      base <> " bg-blue-600 text-white hover:bg-blue-500"
    end
  end
end
