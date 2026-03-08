defmodule GameSiteWeb.GuessingLive do
  use GameSiteWeb, :live_view

  alias GameSiteWeb.Live.GuessingLive.Component, as: GuessingComponent
  alias GameSiteWeb.Live.Component, as: Component
  alias GameSiteWeb.Live.GuessingLive.Question
  alias GameSite.Scores.ScoreHandler

  def render(assigns) do
    ~H"""
    <GuessingComponent.instructions />
    <Component.score_board highest_score={@highest_score} current_score={@score} attempt={@attempt} />

    <GuessingComponent.input_buttons form={@form} />

    <GuessingComponent.wager wager={@wager} score={@score} />

    <Component.score_submit
      form={@form}
      game_id={1}
      score={@highest_score}
      current_user={@current_user}
    />
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(answer: Question.get_new_answer())
      |> assign(score: 10)
      |> assign(attempt: 1)
      |> assign(highest_score: 0)
      |> assign(wager: 1)
      |> assign(form: to_form(%{}))

    {:ok, socket}
  end

  def handle_event("answer", params, socket) do
    Question.handle_answer(params, socket)
  end

  def handle_event("exit", params, socket) do
    ScoreHandler.save_score(socket, params)
  end

  def handle_event("set_max_wager", _params, socket) do
    {:noreply, assign(socket, :wager, socket.assigns.score)}
  end
end
