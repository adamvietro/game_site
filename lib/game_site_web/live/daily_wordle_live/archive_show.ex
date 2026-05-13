defmodule GameSiteWeb.DailyWordleLive.ArchiveShow do
  use GameSiteWeb, :live_view

  alias GameSite.DailyWordle
  alias GameSite.Wordle.GameLogic
  alias GameSiteWeb.WordleLive.GameBoard

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user_wordle =
      DailyWordle.get_user_wordle!(id)
      |> GameSite.Repo.preload(:multi_wordle)

    game_state =
      GameLogic.load_saved_game(
        user_wordle.multi_wordle.word,
        user_wordle.entered_words || [],
        user_wordle.attempts || 0,
        user_wordle.status
      )

    {:ok,
     socket
     |> assign(:page_title, "Archived Wordle")
     |> assign(:user_wordle, user_wordle)
     |> assign(:multi_wordle, user_wordle.multi_wordle)
     |> assign(GameLogic.to_map(game_state))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen px-2 py-3 sm:px-4 select-none">
      <div class="mx-auto flex w-full max-w-lg flex-col gap-4 lg:max-w-3xl">
        <.link
          navigate={~p"/daily-wordle/archive"}
          class="text-sm font-medium text-blue-600 hover:underline"
        >
          Back to archive
        </.link>

        <div class="rounded-lg bg-white p-4 shadow">
          <h1 class="text-xl font-bold">
            Daily Wordle - {@multi_wordle.date}
          </h1>

          <p class="text-sm text-gray-600">
            Status: {@user_wordle.status} · Attempts: {@user_wordle.attempts}
          </p>
        </div>

        <div class="rounded-xl bg-gray-100 p-3 sm:p-4 shadow-inner">
          <GameBoard.game_board board_state={@board_state} entries={@entries} />
        </div>

        <GameBoard.keyboard keyboard={@keyboard_state} />
      </div>
    </div>
    """
  end
end
