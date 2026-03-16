defmodule GameSiteWeb.Live.PokerLive.Component do
  use GameSiteWeb, :live_view
  use Phoenix.Component

  def instructions(assigns) do
    ~H"""
    <h2 class="text-xl font-semibold mb-2">Poker Game Overview</h2>
    <ul class="list-disc list-inside mt-2 space-y-1 text-gray-700">
      <li>Draw 5 cards and choose which ones to keep.</li>
      <li>Adjust your wager before drawing cards.</li>
      <li>Going "all-in" means you cannot reduce your wager afterwards.</li>
      <li>Your goal is to achieve the highest score possible.</li>
      <li>If your score reaches 0, the game resets but keeps track of your highest score.</li>
    </ul>
    """
  end

  def rules(assigns) do
    ~H"""
    <section class="bg-white rounded p-4 shadow max-w-md mx-auto">
      <h3 class="text-lg font-semibold mb-2">Rules</h3>
      <ul class="list-disc list-inside space-y-1 text-gray-700">
        <li>Minimum wager is 10.</li>
        <li>Maximum wager is your current score (money).</li>
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
