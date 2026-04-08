defmodule GameSiteWeb.PokerLive.Component do
  use GameSiteWeb, :live_view
  use Phoenix.Component

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
          <li>Adjust your wager before drawing cards.</li>
          <li>Draw 5 cards and choose which ones to keep.</li>
          <li>A pair of Jacks or higher will pay out.</li>
          <li>Going "all-in" means you cannot reduce your wager afterwards.</li>
          <li>Your goal is to achieve the highest score possible.</li>
          <li>If your score reaches 0, the game resets but keeps track of your highest score.</li>
        </ul>
      </div>
    </div>
    """
  end

  def rules(assigns) do
    ~H"""
    <section class="bg-white rounded p-4 shadow max-w-md mx-auto">
      <h3 class="text-lg font-semibold mb-2">Rules</h3>
      <ul class="list-disc list-inside space-y-1 text-gray-700">
        <li>Minimum wager is 10.</li>
        <li>Maximum wager is your current score.</li>
        <li>You can reset the game only if your score reaches 0.</li>
      </ul>

      <p class="mt-3 text-sm text-gray-600 font-semibold">
        <strong>Note:</strong>
        Please be cautious when increasing your wager, especially when going all-in!
      </p>
    </section>
    """
  end
end
