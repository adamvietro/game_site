defmodule GameSiteWeb.Live.GuessingLive.Component do
  use GameSiteWeb, :live_view
  use Phoenix.Component

  def instructions(assigns) do
    ~H"""
    <h2 class="text-xl font-semibold">Guessing Game Overview</h2>
    <ul class="list-disc list-inside text-left max-w-prose text-gray-700 space-y-1">
      <li>The site picks a random number between 1 and 10.</li>
      <li>You have 5 chances to guess the correct number.</li>
      <li>Adjust your wager amount before each guess.</li>
      <li>Correct guesses increase your score by the wager.</li>
      <li>Incorrect guesses decrease your score by the wager.</li>
      <li>If your score hits 0, your session resets but keeps your high score.</li>
    </ul>
    """
  end

  attr(:form, :map, required: true)

  def input_buttons(assigns) do
    ~H"""
    <div class="grid grid-cols-5 gap-x-3 gap-y-1 max-w-md mx-auto mt-4">
      <%= for guess <- 1..10 do %>
        <.simple_form for={@form} phx-submit="answer" class="text-center">
          <.input type="hidden" field={@form[:guess]} value={guess} id={"guess_hidden_#{guess}"} />

          <input type="hidden" name="wager" id={"wager_hidden_#{guess}"} />

          <.button type="submit" class="w-full" phx-hook="CopyBonus">
            {guess}
          </.button>
        </.simple_form>
      <% end %>
    </div>
    """
  end

  attr(:wager, :integer, required: true)
  attr(:score, :integer, required: true)

  def wager(assigns) do
    ~H"""
    <div class="max-w-xs mx-auto">
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
end
