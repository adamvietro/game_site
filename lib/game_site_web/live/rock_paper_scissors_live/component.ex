defmodule GameSiteWeb.Live.RockPaperScissorsLive.Component do
  use GameSiteWeb, :live_component

  def instructions(assigns) do
    ~H"""
    <div class="text-left mx-auto text-left">
      <h2 class="text-xl font-semibold mb-2">How to Play</h2>
      <p>
        Rock Paper Scissors — simple but fun! Each win earns you the amount you wager
        each loss deducts it. Choose your move and test your luck.
      </p>
      <ul class="list-disc list-inside mt-2 space-y-1 text-gray-700">
        <li>Rock beats Scissors</li>
        <li>Scissors beats Paper</li>
        <li>Paper beats Rock</li>
        <li>If both choose the same move, it's a tie</li>
        <li>Game resets if your score hits 0, but your high score is saved</li>
      </ul>
    </div>
    """
  end

  attr(:form, :map, required: true)
  attr(:wager, :integer, required: true)
  attr(:score, :integer, required: true)
  attr(:parent_id, :string, required: true)

  def input_buttons(assigns) do
    ~H"""
    <%!-- <.simple_form for={@form} phx-submit="answer" class="text-center space-y-6 max-w-xs mx-auto">
      <div>
        <label for="wager_input" class="block text-sm font-medium text-gray-700 mb-1">
          Wager
        </label>
        <input
          type="number"
          id="wager_input"
          name="wager"
          min="1"
          value={@wager}
          max={@score}
          phx-target={@parent_id}
          step="1"
          class="w-full rounded-md border-gray-300 shadow-sm focus:ring-blue-500 focus:border-blue-500"
        />
      </div>

      <input type="hidden" name="player_choice" id="player_choice" />

      <div class="flex justify-center gap-6">
        <%= for choice <- ["rock", "paper", "scissors"] do %>
          <button
            type="submit"
            class="w-24 bg-gray-200 hover:bg-gray-300 shadow rounded"
            phx-click={JS.exec("document.getElementById('player_choice').value = '#{choice}'")}
          >
            {String.capitalize(choice)}
          </button>
        <% end %>
      </div>
    </.simple_form> --%>
    <div class="grid grid-cols-3 gap-x-3 gap-y-1 max-w-md mx-auto mt-4">
      <%= for guess <- ["rock", "paper", "scissors"] do %>
        <.simple_form for={@form} phx-submit="answer" class="text-center">
          <.input
            type="hidden"
            field={@form[:player_choice]}
            value={guess}
            id={"guess_hidden_#{guess}"}
          />

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
end
