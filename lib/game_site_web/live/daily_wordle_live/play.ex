defmodule GameSiteWeb.DailyWordleLive.Play do
  use GameSiteWeb, :live_view

  alias GameSite.DailyWordle
  alias GameSite.Wordle.GameLogic
  alias GameSiteWeb.WordleLive.{Component, GameBoard}
  alias GameSiteWeb.Components.LiveComponents
  alias GameSite.Scores.ScoreHandler

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen px-2 py-3 sm:px-4 select-none">
      <div class="mx-auto flex w-full max-w-lg flex-col gap-4 lg:max-w-3xl">
        <section class="p-2 sm:p-4">
          <div class="mt-4">
            <Component.score_board
              highest_score={@highest_score}
              highest_streak={@highest_streak}
              current_score={@score}
              current_streak={@current_streak}
              reset={@reset}
              word={@word}
            />
          </div>
        </section>

        <div class="rounded-xl bg-gray-100 p-3 sm:p-4 shadow-inner">
          <GameBoard.game_board board_state={@board_state} entries={@entries} />
        </div>

        <Component.user_input form={@form} reset={@reset} guess_string={@guess_string} />

        <GameBoard.keyboard keyboard={@keyboard_state} />

        <LiveComponents.score_submit
          form={@form}
          game_id={4}
          score={@highest_score}
          current_user={@current_user}
        />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> default_assigns()
      |> maybe_connected()

    {:ok, socket}
  end

  defp maybe_connected(socket) do
    if connected?(socket) do
      socket
      |> initial_state()
    else
      socket
    end
  end

  def initial_state(socket) do
    current_user = socket.assigns.current_user
    multi_wordle = DailyWordle.get_or_create_today_wordle()

    {:ok, user_wordle} =
      DailyWordle.get_or_create_user_wordle(current_user.id, multi_wordle.id)

    %GameLogic{
      word: multi_wordle,
      round: user_wordle.attempts || 0,
      entries: user_wordle.entered_words || GameLogic.get_starting_entries()
    }

    socket
  end

  defp default_assigns(socket) do
    socket
    |> assign(form: to_form(%{"guess" => ""}))
    |> assign(GameLogic.to_map(GameLogic.new()))
  end

  defp assign_game_state(%GameLogic{errors: errors} = game_state, socket) do
    socket =
      if errors do
        assign(socket,
          form: to_form(%{"guess" => ""}, errors: [guess: {errors, []}])
        )
        |> assign(GameLogic.to_map(game_state))
      else
        assign(socket,
          form: to_form(%{"guess" => ""})
        )
        |> assign(GameLogic.to_map(game_state))
      end

    {:noreply, socket}
  end
end
