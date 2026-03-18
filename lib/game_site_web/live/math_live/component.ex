defmodule GameSiteWeb.Live.MathLive.Component do
  use GameSiteWeb, :live_view
  use Phoenix.Component

  def instructions(assigns) do
    ~H"""
    <h2 class="text-xl font-semibold mb-2">Math Game Overview</h2>
    <ul class="list-disc list-inside mt-2 space-y-1 text-gray-700">
      <li>Each round presents a basic math equation using numbers from 1 to 100.</li>
      <li>Before answering, you choose how many points to wager.</li>
      <li>If your answer is correct, you gain the wagered points.</li>
      <li>If you're wrong, the wager is subtracted from your score.</li>
      <li>When your score reaches 0, the game resets—but your highest score is saved.</li>
      <li>The goal is to maintain a streak and beat your personal best!</li>
    </ul>
    """
  end

  attr(:helper, :map, required: true)
  attr(:toggle, :boolean, required: true)

  def helper_board(assigns) do
    ~H"""
    <div class="bg-white shadow-md rounded p-4 space-y-4 border border-gray-300 h-64">
      <p>
        Toggle the helper function if you want a hint or want to hide it:
      </p>
      <label class="flex items-center space-x-2 cursor-pointer" phx-click="toggle">
        <input type="checkbox" class="sr-only" checked={@toggle} readonly />
        <div class="w-10 h-5 bg-gray-300 rounded-full relative">
          <div class={"w-5 h-5 bg-white rounded-full shadow absolute top-0 transition-transform #{if @toggle, do: "translate-x-5", else: "translate-x-0"}"}>
          </div>
        </div>
        <span>Show Helper</span>
      </label>

      <div class={if @toggle, do: "", else: "invisible"}>
        <p>{@helper.first}</p>
        <p>{@helper.second}</p>
        <p>{@helper.third}</p>
        <p>{@helper.fourth}</p>
      </div>
    </div>
    """
  end

  def question(assigns) do
    ~H"""
    <section class="bg-gray-50 rounded p-4 shadow text-center">
      <div>
        <div class="text-sm text-gray-500">Question</div>
        <div>{@question}</div>
      </div>
    </section>
    """
  end
end
