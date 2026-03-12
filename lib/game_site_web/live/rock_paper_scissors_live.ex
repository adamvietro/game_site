defmodule GameSiteWeb.RockPaperScissorsLive do
  use GameSiteWeb, :live_view

  alias GameSiteWeb.Live.RockPaperScissorsLive.GameLogic
  alias GameSiteWeb.Live.RockPaperScissorsLive.Component, as: RPSComponent
  alias GameSiteWeb.Live.Component, as: Component
  alias GameSite.Scores.ScoreHandler

  @impl true
  def render(assigns) do
    ~H"""
    <section class="bg-gray-50 rounded p-4 shadow space-y-4">
      <RPSComponent.instructions />
      <Component.score_board highest_score={@highest_score} current_score={@score} outcome={@outcome} />
    </section>

    <section>
      <RPSComponent.input_buttons form={@form} wager={@wager} score={@score} parent_id={@socket.id} />
      <RPSComponent.wager wager={@wager} score={@score} />
    </section>
    <Component.score_submit
      form={@form}
      game_id={3}
      score={@highest_score}
      current_user={@current_user}
    />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    computer_choice =
      if connected?(socket),
        do: GameLogic.set_computer_choice(),
        else: nil

    socket =
      socket
      |> assign(computer: computer_choice)
      |> assign(score: 10)
      |> assign(highest_score: 0)
      |> assign(wager: 1)
      |> assign(form: to_form(%{"wager" => 1}))
      |> assign(outcome: "")

    {:ok, socket}
  end

  @impl true
  def handle_event("exit", params, socket) do
    ScoreHandler.save_score(socket, params)
  end

  @impl true
  def handle_event("answer", params, socket) do
    GameLogic.set_game_board_info(socket, params)
  end

  @impl true
  def handle_event("set_max_wager", _params, socket) do
    {:noreply, assign(socket, :wager, socket.assigns.score)}
  end
end
