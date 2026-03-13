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
      <Component.score_board highest_score={@highest_score} current_score={@score} outcome={@message} />
    </section>

    <section>
      <RPSComponent.input_buttons form={@form} wager={@wager} score={@score} />
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
    computer =
      if connected?(socket), do: GameLogic.set_computer_choice()

    {:ok, assign(socket, default_state(computer))}
  end

  @impl true
  def handle_event("exit", params, socket) do
    ScoreHandler.save_score(socket, params)
  end

  @impl true
  def handle_event("answer", params, socket) do
    game_state =
      %GameLogic{
        player: params["player_choice"],
        computer: socket.assigns.computer,
        score: socket.assigns.score,
        highest_score: socket.assigns.highest_score,
        wager: GameLogic.parse_wager(params["wager"]),
        form: to_form(%{"wager" => params["wager"]})
      }

    game_state
    |> GameLogic.determine_round()
    |> assign_game_state(socket)
  end

  @impl true
  def handle_event("set_max_wager", _params, socket) do
    {:noreply, assign(socket, :wager, socket.assigns.score)}
  end

  defp assign_game_state(%GameLogic{} = game_state, socket) do
    socket =
      socket
      |> put_flash(:error, game_state.flash_message)
      |> assign(computer: game_state.computer)
      |> assign(score: game_state.score)
      |> assign(wager: game_state.wager)
      |> assign(highest_score: game_state.highest_score)
      |> assign(form: to_form(%{"wager" => game_state.wager}))
      |> assign(outcome: nil)
      |> assign(message: game_state.message)

    {:noreply, socket}
  end

  defp default_state(computer) do
    %{
      computer: computer,
      score: 10,
      highest_score: 0,
      wager: 1,
      form: to_form(%{"wager" => 1}),
      message: ""
    }
  end
end
