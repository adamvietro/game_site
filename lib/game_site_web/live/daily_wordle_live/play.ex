defmodule GameSiteWeb.DailyWordleLive.Play do
  use GameSiteWeb, :live_view

  alias GameSite.DailyWordle
  alias GameSite.Wordle.GameLogic
  alias GameSiteWeb.WordleLive.{Component, GameBoard}
  alias GameSiteWeb.Components.LiveComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen px-2 py-3 sm:px-4 select-none">
      <div class="mx-auto flex w-full max-w-lg flex-col gap-4 lg:max-w-3xl">
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

  @impl true
  def handle_event("delete_letter", _, socket) do
    if socket.assigns.guess_string == "" do
      {:noreply, socket}
    else
      updated = socket.assigns.guess_string |> String.slice(0..-2//1)
      {:noreply, assign(socket, guess_string: updated)}
    end
  end

  @impl true
  def handle_event("add_letter", %{"letter" => letter}, socket) do
    current = socket.assigns.guess_string || ""

    if String.length(current) < 5 do
      updated = String.slice(current <> letter, 0, 5)
      {:noreply, assign(socket, guess_string: updated)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("guess", %{"guess" => guess}, %{assigns: %{user_wordle: user_wordle}} = socket) do
    game_state =
      GameLogic.new(socket.assigns, guess)
      |> GameLogic.determine_round()

    if game_state.errors do
      assign_game_state(game_state, socket)
    else
      status = status_from_game_state(game_state)

      {:ok, user_wordle} =
        DailyWordle.update_user_wordle(user_wordle, %{
          entered_words: (user_wordle.entered_words || []) ++ [guess],
          attempts: game_state.round,
          status: status,
          completed_at: completed_at(status)
        })

      socket =
        assign(socket, :user_wordle, user_wordle)

      assign_game_state(game_state, socket)
    end
  end

  @impl true
  def handle_event("guess", _, socket) do
    {:noreply, put_flash(socket, :error, "Invalid guess submission")}
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

    state =
      GameLogic.load_saved_game(
        multi_wordle.word,
        user_wordle.entered_words,
        user_wordle.attempts,
        user_wordle.status
      )

    socket
    |> assign(GameLogic.to_map(state))
    |> assign(user_wordle: user_wordle)
  end

  defp default_assigns(socket) do
    socket
    |> assign(form: to_form(%{"guess" => ""}))
    |> assign(GameLogic.to_map(GameLogic.new()))
  end

  defp assign_game_state(%GameLogic{errors: errors} = game_state, socket) do
    socket =
      if errors do
        socket
        |> assign(form: to_form(%{"guess" => ""}, errors: [guess: {errors, []}]))
        |> assign(GameLogic.to_map(game_state))
      else
        socket
        |> assign(form: to_form(%{"guess" => ""}))
        |> assign(GameLogic.to_map(game_state))
      end

    {:noreply, socket}
  end

  defp status_from_game_state(%{win?: true}), do: "won"
  defp status_from_game_state(%{reset: true}), do: "lost"
  defp status_from_game_state(_game_state), do: "playing"

  defp completed_at("playing"), do: nil

  defp completed_at(_status) do
    DateTime.utc_now() |> DateTime.truncate(:second)
  end
end
