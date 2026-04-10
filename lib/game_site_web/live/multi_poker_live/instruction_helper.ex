defmodule GameSiteWeb.MultiPokerLive.InstructionHelper do
  use Phoenix.Component

  def helper_bubble(assigns) do
    ~H"""
    <div id="poker-rules-help" phx-hook="HelpBubble" class="relative inline-block">
      <button
        type="button"
        data-help-button
        class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-gray-200 text-sm font-bold text-gray-700 hover:bg-gray-300"
        aria-label="Show game rules"
      >
        ?
      </button>

      <div
        data-help-panel
        class="absolute left-0 top-full z-50 mt-2 w-72 max-w-[calc(100vw-1rem)] rounded-xl border border-gray-200 bg-white p-3 shadow-lg text-xs sm:text-sm"
      >
        <h3 class="mb-2 text-sm font-semibold text-gray-900">Poker Rules</h3>

        <div class="space-y-2 text-sm text-gray-700">
          <p>Each player is dealt 2 hole cards.</p>
          <p>Betting happens across pre-flop, flop, turn, and river.</p>
          <p>If all but one player folds, that player wins immediately.</p>
          <p>If all remaining players are all-in, the board runs out automatically.</p>
          <p>The best 5-card hand wins.</p>
          <p>
            If you bust, you can come back with 1000 chips after leaving the table or being removed.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
