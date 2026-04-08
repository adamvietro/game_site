defmodule GameSiteWeb.MathLive do
  use GameSiteWeb, :live_view

  alias GameSiteWeb.MathLive.Component
  alias GameSiteWeb.Components.LiveComponents
  alias GameSite.Math.{Question, GameLogic, Game}
  alias GameSite.Scores.ScoreHandler

  @helper_start %{
    first: "Loading...",
    second: "Loading...",
    third: "Loading...",
    fourth: "Loading..."
  }

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto flex w-full max-w-6xl flex-col gap-6 px-4 sm:px-6 lg:px-8">
      <LiveComponents.game_header
        highest_score={@game.highest_score}
        current_score={@game.score}
        id="MathGame"
        question={@game.question}
        instructions={[
          %{text: "Each round presents a basic math equation using numbers from 1 to 100."},
          %{text: "Before answering, you choose how many points to wager."},
          %{text: "If your answer is correct, you gain the wagered points."},
          %{text: "If you're wrong, the wager is subtracted from your score."},
          %{text: "When your score reaches 0, the game resets—but your highest score is saved."},
          %{text: "The goal is to maintain a streak and beat your personal best!"}
        ]}
      />

      <div class="grid grid-cols-1 lg:grid-cols-2">
        <Component.answer_submit form={@form} score={@game.score} wager={@game.wager} />
        <Component.helper_board helper={@game.helper} toggle={@game.toggle} />
      </div>

      <LiveComponents.score_submit
        form={@form}
        game_id={2}
        score={@game.highest_score}
        current_user={@current_user}
      />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    game =
      if connected?(socket) do
        GameLogic.new_game(:connected)
      else
        GameLogic.new_game(:disconnected)
      end

    socket =
      socket
      |> assign(:game, game)
      |> assign(:form, build_form(game))
      |> push_event("focus-guess", %{})

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    game = GameLogic.toggle_helper(socket.assigns.game)

    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("answer", %{"guess" => _guess, "wager" => _wager} = params, socket) do
    game = GameLogic.submit_answer(socket.assigns.game, params)

    socket =
      socket
      |> clear_flash()
      |> assign(:game, game)
      |> assign(:form, build_form(game))
      |> maybe_put_flash(game)
      |> push_event("focus-guess", %{})

    {:noreply, socket}
  end

  def handle_event("exit", params, socket) do
    ScoreHandler.save_score(socket, params)
  end

  defp build_form(%Game{} = game) do
    params = %{
      "guess" => "",
      "wager" => game.wager
    }

    case game.message do
      nil ->
        to_form(params)

      "" ->
        to_form(params)

      msg ->
        to_form(
          params,
          errors: [guess: {msg, [type: game.message_type]}]
        )
    end
  end

  defp maybe_put_flash(socket, %Game{flash_type: nil}), do: socket
  defp maybe_put_flash(socket, %Game{flash_msg: ""}), do: socket

  defp maybe_put_flash(socket, %Game{} = game) do
    put_flash(socket, game.flash_type, game.flash_msg)
  end
end
