defmodule GameSiteWeb.RockPaperScissorsLive.Component do
  use GameSiteWeb, :live_component

  def instructions(assigns) do
    ~H"""
    <div id="help-bubble" phx-hook="HelpBubble" class="relative inline-flex justify-center">
      <button
        type="button"
        data-help-button
        class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-blue-500 text-sm font-bold text-white shadow hover:bg-blue-600"
        aria-label="Show instructions"
      >
        ?
      </button>

      <div
        data-help-panel
        class="absolute right-0 top-full z-50 mt-2 w-72 max-w-[calc(100vw-2rem)] rounded-xl border border-gray-200 bg-white p-3 text-xs text-gray-700 shadow-lg sm:text-sm"
      >
        <h3 class="mb-2 text-sm font-semibold text-gray-900">How to play</h3>

        <ul class="space-y-2 text-sm text-gray-700">
          <li>Rock beats Scissors</li>
          <li>Scissors beats Paper</li>
          <li>Paper beats Rock</li>
          <li>If both choose the same move, it's a tie</li>
          <li>Game resets if your score hits 0, but your high score is saved</li>
        </ul>
      </div>
    </div>
    """
  end

  attr(:form, :map, required: true)
  attr(:wager, :integer, required: true)
  attr(:score, :integer, required: true)

  def input_buttons(assigns) do
    ~H"""
    <div class="mt-4 w-full">
      <form id="answer-form" phx-submit="answer" class="rounded-xl bg-white p-4 shadow-md">
        <.error_message form={@form} />

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-4 sm:gap-3">
          <div class="sm:col-span-3">
            <label class="mb-2 block text-sm font-medium text-gray-700">
              Choice
            </label>

            <div class="grid grid-cols-3 gap-2">
              <button
                id="rps-rock"
                type="submit"
                name="player_choice"
                value="rock"
                phx-hook="CopyBonus"
                class="w-full rounded-lg bg-blue-500 px-3 py-2 text-white shadow hover:bg-blue-600"
              >
                Rock
              </button>

              <button
                id="rps-paper"
                type="submit"
                name="player_choice"
                value="paper"
                phx-hook="CopyBonus"
                class="w-full rounded-lg bg-blue-500 px-3 py-2 text-white shadow hover:bg-blue-600"
              >
                Paper
              </button>

              <button
                id="rps-scissors"
                type="submit"
                name="player_choice"
                value="scissors"
                phx-hook="CopyBonus"
                class="w-full rounded-lg bg-blue-500 px-3 py-2 text-white shadow hover:bg-blue-600"
              >
                Scissors
              </button>
            </div>
          </div>

          <div class="sm:col-span-1">
            <label for="wager_input" class="mb-2 block text-sm font-medium text-gray-700">
              Wager
            </label>

            <input
              id="wager_input"
              name="wager"
              type="number"
              min="1"
              max={@score}
              value={@wager}
              class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>
        </div>
      </form>
    </div>
    """
  end

  attr(:wager, :integer, required: true)
  attr(:score, :integer, required: true)

  def wager(assigns) do
    ~H"""
    <div class="grid grid-cols-1 gap-y-2 max-w-md mx-auto">
      <label for="wager_input" class="block text-sm font-medium text-gray-700 mb-1">
        Wager
      </label>
      <input
        type="number"
        id="wager_input"
        name="wager_visible"
        min="1"
        value={@wager}
        max={@score}
        step="1"
        class="w-full rounded-md border-gray-300 shadow-sm focus:ring-blue-500 focus:border-blue-500"
      />
      <button
        type="button"
        phx-click="set_max_wager"
        class="mt-6 px-2 py-1 bg-blue-500 text-white rounded hover:bg-blue-600 text-sm"
      >
        Max
      </button>
    </div>

    <br /> <br />
    """
  end

  attr(:form, :map, required: true)

  def error_message(assigns) do
    ~H"""
    <div class="min-h-[28px] flex items-center justify-center">
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
    </div>
    """
  end
end
