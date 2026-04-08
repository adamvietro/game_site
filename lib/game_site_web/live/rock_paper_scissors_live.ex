defmodule GameSiteWeb.RockPaperScissorsLive do
  use GameSiteWeb, :live_view

  alias GameSiteWeb.Live.RockPaperScissorsLive.{Component, GameLogic}
  alias GameSiteWeb.Components.LiveComponents
  alias GameSite.Scores.ScoreHandler

  @impl true
  def render(assigns) do
    ~H"""
    <section class="bg-gray-50 rounded p-4 shadow space-y-4">
      <Component.instructions />
      <LiveComponents.score_board
        highest_score={@highest_score}
        current_score={@score}
        outcome={@message}
      />
    </section>

    <section>
      <Component.input_buttons form={@form} wager={@wager} score={@score} />
      <Component.wager wager={@wager} score={@score} />
    </section>
    <LiveComponents.score_submit
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

  @impl true
  def handle_event("exit", params, socket) do
    ScoreHandler.save_score(socket, params)
  end

  defp assign_game_state(%GameLogic{} = game_state, socket) do
    socket =
      socket
      |> assign(computer: game_state.computer)
      |> assign(score: game_state.score)
      |> assign(wager: game_state.wager)
      |> assign(highest_score: game_state.highest_score)
      |> assign(form: to_form(%{"wager" => game_state.wager}))
      |> assign(outcome: game_state.outcome)
      |> assign(message: game_state.message)

    socket =
      if game_state.flash_message do
        put_flash(socket, :error, game_state.flash_message)
      else
        socket
      end

    {:noreply, socket}
  end

  defp default_state(computer) do
    %{
      computer: computer,
      score: 10,
      highest_score: 0,
      wager: 1,
      form: to_form(%{"wager" => 1}),
      message: "",
      outcome: ""
    }
  end
end
