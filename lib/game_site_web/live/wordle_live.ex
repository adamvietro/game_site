defmodule GameSiteWeb.WordleLive do
  use GameSiteWeb, :live_view

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
  def handle_event("guess", %{"guess" => guess} = _params, socket) do
    IO.inspect(%{answer: socket.assigns.word, guess: guess}, label: "Guess Event")

    GameLogic.new(socket.assigns, guess)
    |> GameLogic.determine_round()
    |> assign_game_state(socket)
  end

  @impl true
  def handle_event("guess", _, socket) do
    {:noreply, put_flash(socket, :error, "Invalid guess submission")}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    socket =
      socket
      |> assign(round: 0)
      |> assign(reset: false)
      |> assign(guess_string: "")
      |> assign(form: to_form(%{"guess" => ""}))
      |> assign(word: GameLogic.get_new_word())
      |> assign(entries: GameLogic.get_starting_entries())
      |> assign(keyboard_state: GameLogic.get_starting_keyboard())
      |> assign(board_state: GameLogic.get_starting_board())

    {:noreply, socket}
  end

  @impl true
  def handle_event("exit", params, socket) do
    ScoreHandler.save_score(socket, params)
  end

  defp maybe_connected(socket) do
    if connected?(socket) do
      socket
      |> assign(word: GameLogic.get_new_word())
    else
      socket
    end
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
