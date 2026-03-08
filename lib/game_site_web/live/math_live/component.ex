defmodule GameSiteWeb.Live.MathLive.Component do
  use GameSiteWeb, :live_view
  use Phoenix.Component

  def instructions(assigns) do
  ~H"""
  <section class="bg-gray-50 rounded p-4 shadow">
      <h2 class="text-xl font-semibold mb-2">Math Game Overview</h2>
      <ul class="list-disc list-inside mt-2 space-y-1 text-gray-700">
        <li>Each round presents a basic math equation using numbers from 1 to 100.</li>
        <li>Before answering, you choose how many points to wager.</li>
        <li>If your answer is correct, you gain the wagered points.</li>
        <li>If you're wrong, the wager is subtracted from your score.</li>
        <li>When your score reaches 0, the game resets—but your highest score is saved.</li>
        <li>The goal is to maintain a streak and beat your personal best!</li>
        <%!-- <li>{@current_user}</li> --%>
      </ul>

  """
  end
end
