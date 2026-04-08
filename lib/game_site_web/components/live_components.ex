defmodule GameSiteWeb.Components.LiveComponents do
  use GameSiteWeb, :live_view
  use Phoenix.Component

  attr(:form, :map, required: true)
  attr(:game_id, :integer, required: true)
  attr(:score, :integer, required: true)
  attr(:current_user, :map, required: false)

  def score_submit(assigns) do
    ~H"""
    <div class="rounded bg-white p-4 shadow-md">
      <%= if @current_user == nil do %>
        <p>
          If you want to submit your score please make an
          <a
            href="/users/register"
            style="cursor: pointer; text-decoration: none; color: blue;"
            onmouseover="this.style.textDecoration='underline'; this.style.color='red';"
            onmouseout="this.style.textDecoration='none'; this.style.color='blue';"
          >
            account
          </a>
        </p>
      <% else %>
        <.simple_form id="exit-form" for={@form} phx-submit="exit">
          <.input type="hidden" field={@form[:user_id]} value={@current_user.id} name="user" />
          <.input type="hidden" field={@form[:game_id]} value={@game_id} name="game" />
          <.input type="hidden" field={@form[:score]} value={@score} name="score" />
          <:actions>
            <.button class="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded shadow">
              Exit and Save Score
            </.button>
          </:actions>
        </.simple_form>
      <% end %>
    </div>
    """
  end

  attr(:highest_score, :integer, required: true)
  attr(:current_score, :integer, required: true)
  attr(:attempt, :integer, default: nil)
  attr(:outcome, :string, default: nil)
  attr(:current_bet, :integer, default: nil)
  attr(:instructions, :list, required: true)
  attr(:id, :string, required: true)

  def game_header(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-4xl px-4 sm:px-6">
      <div class="flex items-start justify-center gap-3">
        <div class="min-w-0">
          <.score_board
            highest_score={@highest_score}
            current_score={@current_score}
            attempt={@attempt}
            outcome={@outcome}
            current_bet={@current_bet}
          />
        </div>

        <div class="shrink-0 pt-4">
          <.instructions id={@id} instructions={@instructions} />
        </div>
      </div>
    </div>
    """
  end

  attr(:highest_score, :integer, required: true)
  attr(:current_score, :integer, required: true)
  attr(:attempt, :integer, default: nil)
  attr(:outcome, :string, default: nil)
  attr(:current_bet, :integer, default: nil)

  def score_board(assigns) do
    ~H"""
    <div class="mt-4 flex flex-wrap justify-center gap-2 text-center sm:gap-3">
      <div class="min-w-[90px] rounded-lg bg-white px-3 py-2 shadow sm:min-w-[120px] sm:px-4 sm:py-3">
        <div class="text-xs text-gray-500 sm:text-sm">Highest Score</div>
        <div class="text-base font-semibold text-gray-800 sm:text-lg">{@highest_score}</div>
      </div>

      <div class="min-w-[90px] rounded-lg bg-white px-3 py-2 shadow sm:min-w-[120px] sm:px-4 sm:py-3">
        <div class="text-xs text-gray-500 sm:text-sm">Current Score</div>
        <div class="text-base font-semibold text-gray-800 sm:text-lg">{@current_score}</div>
      </div>

      <%= if @attempt do %>
        <div class="min-w-[90px] rounded-lg bg-white px-3 py-2 shadow sm:min-w-[120px] sm:px-4 sm:py-3">
          <div class="text-xs text-gray-500 sm:text-sm">Attempt</div>
          <div class="text-base font-semibold text-gray-800 sm:text-lg">{@attempt}</div>
        </div>
      <% end %>

      <%= if @outcome do %>
        <div class="min-w-[90px] rounded-lg bg-white px-3 py-2 shadow sm:min-w-[120px] sm:px-4 sm:py-3">
          <div class="text-xs text-gray-500 sm:text-sm">Outcome</div>
          <div class="text-base font-semibold text-blue-600 sm:text-lg">{@outcome}</div>
        </div>
      <% end %>

      <%= if @current_bet do %>
        <div class="min-w-[90px] rounded-lg bg-white px-3 py-2 shadow sm:min-w-[120px] sm:px-4 sm:py-3">
          <div class="text-xs text-gray-500 sm:text-sm">Current Bet</div>
          <div class="text-base font-semibold text-gray-800 sm:text-lg">{@current_bet}</div>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:instructions, :list, required: true)
  attr(:id, :string, required: true)

  def instructions(assigns) do
    ~H"""
    <div id={@id} phx-hook="HelpBubble" class="relative inline-flex justify-center">
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
          <%= for item <- @instructions do %>
            <li>
              <%= if item[:label] do %>
                <span class={item[:class]}>{item[:label]}</span>: {item[:text]}
              <% else %>
                {item[:text]}
              <% end %>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end
end
