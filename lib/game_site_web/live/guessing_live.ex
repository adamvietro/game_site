defmodule GameSiteWeb.GuessingLive do
  use GameSiteWeb, :live_view

  alias GameSiteWeb.GuessingLive.Component
  alias GameSiteWeb.Components.LiveComponents
  alias GameSite.Guessing.GameLogic
  alias GameSite.Scores.ScoreHandler

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto flex w-full max-w-4xl flex-col gap-4 px-4 sm:px-6 ">
      <LiveComponents.game_header
        id="GuessingInstructions"
        highest_score={@game.highest_score}
        current_score={@game.score}
        attempt={@game.attempt}
        instructions={[
          %{text: "The site picks a random number between 1 and 10."},
          %{text: "You have 5 chances to guess the correct number."},
          %{text: "Adjust your wager amount before each guess."},
          %{text: "Correct guesses increase your score by the wager."},
          %{text: "Incorrect guesses decrease your score by the wager."},
          %{text: "If your score hits 0, your session resets but keeps your high score."}
        ]}
      />

      <div class="w-full">
        <Component.input_buttons form={@form} guessed_numbers={@game.guessed_numbers} />
      </div>

      <div class="w-full">
        <Component.wager wager={@game.wager} score={@game.score} form={@form} />
      </div>

      <div class="w-full">
        <LiveComponents.score_submit
          form={@form}
          game_id={1}
          score={@game.highest_score}
          current_user={@current_user}
        />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    game = GameLogic.new_game()

    socket =
      socket
      |> assign(:game, game)
      |> assign(:form, to_form(%{}))

    {:ok, socket}
  end

  @impl true
  def handle_event("answer", params, socket) do
    game = GameLogic.submit_guess(socket.assigns.game, params)

    form =
      case game.message do
        nil -> to_form(%{})
        "" -> to_form(%{})
        "Correct!" -> to_form(%{}, errors: [guess: {"Correct!", [type: :info]}])
        msg -> to_form(%{}, errors: [guess: {msg, [type: :error]}])
      end

    socket =
      socket
      |> clear_flash()
      |> assign(:game, game)
      |> assign(:form, form)
      |> put_flash(game.flash_type, game.flash_msg)

    {:noreply, socket}
  end

  @impl true
  def handle_event("exit", params, socket) do
    ScoreHandler.save_score(socket, params)
  end

  @impl true
  def handle_event("set_max_wager", _params, socket) do
    game = GameLogic.update_to_max_bet(socket.assigns.game)
    {:noreply, assign(socket, game: game)}
  end
end
