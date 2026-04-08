defmodule GameSiteWeb.Live.WordleLive.Component do
  use GameSiteWeb, :live_view

  def instructions(assigns) do
    ~H"""
    <div id="wordle-rules-help" phx-hook="HelpBubble" class="relative inline-block">
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
        class="absolute right-0 top-full z-50 mt-2 w-72 max-w-[calc(100vw-1rem)] rounded-xl border border-gray-200 bg-white p-3 text-xs text-gray-700 shadow-lg sm:text-sm"
      >
        <h3 class="mb-2 text-sm font-semibold text-gray-900">How to play</h3>

        <div class="space-y-2 text-sm text-gray-700">
          <p><span class="font-semibold text-green-600">Green</span>: right letter, right spot</p>
          <p><span class="font-semibold text-yellow-500">Yellow</span>: right letter, wrong spot</p>
          <p><span class="font-semibold text-gray-500">Gray</span>: not in the word</p>
          <p>Guess the word in 6 tries.</p>
        </div>
      </div>
    </div>
    """
  end

  attr(:highest_score, :integer, required: true)
  attr(:highest_streak, :integer, required: true)
  attr(:current_score, :integer, required: true)
  attr(:current_streak, :integer, required: true)
  attr(:reset, :boolean, required: true)
  attr(:word, :string, required: true)

  def score_board(assigns) do
    ~H"""
    <div class="flex items-center justify-between rounded bg-white px-3 py-2 text-xs text-gray-700 shadow sm:text-sm">
      <div>High: <span class="font-semibold">{@highest_score}</span></div>
      <div>Streak: <span class="font-semibold">{@highest_streak}</span></div>
      <div>Score: <span class="font-semibold">{@current_score}</span></div>
      <div>Run: <span class="font-semibold">{@current_streak}</span></div>
      <.instructions />
    </div>
    """
  end

  attr(:form, :map, required: true)
  attr(:reset, :boolean, required: true)
  attr(:guess_string, :string, required: true)

  def user_input(assigns) do
    ~H"""
    <%= if @reset do %>
      <div class="rounded bg-gray-100 p-2 text-center">
        <form id="input-form" phx-submit="reset">
          <button type="submit" class="w-full rounded-md bg-zinc-800 px-4 py-2 text-sm text-white">
            Reset
          </button>
        </form>
      </div>
    <% else %>
      <div class="p-1">
        <form id="input-form" phx-submit="guess">
          <div class="flex items-center gap-2">
            <div class="flex min-h-10 flex-1 items-center rounded-md border border-gray-300 bg-white px-3 text-sm uppercase tracking-wide text-gray-900">
              {@guess_string}
            </div>

            <input type="hidden" name="guess" value={@guess_string} />

            <button type="submit" class="shrink-0 rounded-md bg-zinc-800 px-4 py-2 text-sm text-white">
              Submit
            </button>
          </div>
        </form>
      </div>
    <% end %>
    """
  end
end
