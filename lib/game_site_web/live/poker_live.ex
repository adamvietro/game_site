defmodule GameSiteWeb.PokerLive do
  use GameSiteWeb, :live_view

  alias GameSiteWeb.Components.LiveComponents
  alias GameSiteWeb.Live.PokerLive.{Component, GameBoard, GameLogic}
  alias GameSite.Scores.ScoreHandler

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-4 space-y-8">
      <Component.instructions />
      <LiveComponents.score_board
        highest_score={@highest_score}
        current_score={@game.score}
        current_bet={@game.wager}
      />

      <GameBoard.game_board
        form={@form}
        hand={@game.hand}
        score={@game.score}
        wager={@game.wager}
        state={@game.state}
        all_in={@game.all_in}
      />
      <Component.rules />

      <LiveComponents.score_submit
        form={@form}
        game_id={5}
        score={@highest_score}
        current_user={@current_user}
      />
    </div>
    """
  end

  @impl true

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(game: GameLogic.new_game())
      |> assign(form: %{})
      |> assign(highest_score: 0)

    {:ok, socket}
  end

  @impl true
  def handle_event("advance", params, socket) do
    advanced_game = GameLogic.advance_game(socket.assigns.game, params)

    socket =
      socket
      |> assign(game: advanced_game)
      |> assign(highest_score: max(advanced_game.score, socket.assigns.highest_score))

    {:noreply, socket}
  end

  @impl true
  def handle_event("new-hand", _params, %{assigns: %{game: game}} = socket) do
    valid =
      %{
        hand: [],
        cards: [],
        state: "initial",
        all_in: false
      }

    {:noreply, assign(socket, game: GameLogic.modify_game(game, valid))}
  end

  @impl true
  def handle_event("reset", _params, %{assigns: %{game: game}} = socket) do
    valid = %{
      score: 100,
      bet: 0,
      hand: [],
      cards: [],
      wager: 10,
      state: "initial",
      all_in: false
    }

    socket = assign(socket, game: GameLogic.modify_game(game, valid))

    {:noreply, socket}
  end

  @impl true
  def handle_event("all-in", _params, %{assigns: %{game: game}} = socket) do
    valid = %{
      all_in: true,
      wager: game.score
    }

    socket = assign(socket, game: GameLogic.modify_game(game, valid))

    {:noreply, socket}
  end

  @impl true
  def handle_event("increase_wager", _params, %{assigns: %{all_in: true}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("decrease_wager", _params, %{assigns: %{game: %{all_in: true}}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("increase_wager", _params, %{assigns: %{game: game}} = socket) do
    new_wager = min(game.wager + 10, game.score)

    all_in = new_wager == game.score

    socket =
      assign(socket, game: GameLogic.modify_game(game, %{all_in: all_in, wager: new_wager}))

    {:noreply, socket}
  end

  @impl true
  def handle_event("decrease_wager", _params, %{assigns: %{game: game}} = socket) do
    new_wager = max(game.wager - 10, 10)

    socket = assign(socket, game: GameLogic.modify_game(game, %{wager: new_wager}))

    {:noreply, socket}
  end

  @impl true
  def handle_event("exit", params, socket) do
    ScoreHandler.save_score(socket, params)
  end
end
