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
  attr(:attempt, :integer, default: nil, required: false)
  attr(:outcome, :string, default: nil, required: false)
  attr(:current_bet, :integer, default: nil, required: false)

  def score_board(assigns) do
    ~H"""
    <div class="mt-4 flex justify-center gap-8 text-center font-semibold text-gray-800">
      <div>
        <div class="text-sm text-gray-500">Highest Score</div>
        <div>{@highest_score}</div>
      </div>
      <div>
        <div class="text-sm text-gray-500">Current Score</div>
        <div>{@current_score}</div>
      </div>
      <%= if @attempt != nil do %>
        <div>
          <div class="text-sm text-gray-500">Attempt</div>
          <div>{@attempt}</div>
        </div>
      <% end %>
      <%= if @outcome != nil do %>
        <div>
          <div class="text-sm text-gray-500">Outcome</div>
          <div class="text-md text-blue-600 font-medium">{@outcome}</div>
        </div>
      <% end %>
      <%= if @current_bet != nil do %>
        <div>
          <div class="text-sm text-gray-500">Current Bet</div>
          <div>{@current_bet}</div>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:instructions, :map, required: true)
  attr(:id, :string, required: true)

  def instructions(assigns) do
    ~H"""
    <div id={@id} phx-hook="HelpBubble" class="relative inline-block">
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
          <%= for item <- @instructions do %>
            <p>
              <%= if is_map(item) do %>
                <span class={item[:class]}>{item[:label]}</span>: {item[:text]}
              <% else %>
                {item}
              <% end %>
            </p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
