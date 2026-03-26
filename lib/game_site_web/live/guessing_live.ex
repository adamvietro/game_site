defmodule GameSiteWeb.GuessingLive do
  use GameSiteWeb, :live_view

  alias GameSiteWeb.Live.GuessingLive.{Component, Question}
  alias GameSiteWeb.Live.Component, as: LiveComponent
  alias GameSite.Scores.ScoreHandler

  @impl true
  def render(assigns) do
    ~H"""
    <Component.instructions />
    <LiveComponent.score_board
      highest_score={@highest_score}
      current_score={@score}
      attempt={@attempt}
    />

    <Component.input_buttons form={@form} />

    <Component.wager wager={@wager} score={@score} />

    <LiveComponent.score_submit
      form={@form}
      game_id={1}
      score={@highest_score}
      current_user={@current_user}
    />
    """
  end

  @impl true
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

  @impl true
  def handle_event("answer", params, socket) do
    event_info = Question.set_event_info(socket.assigns, params)
    new_answer = Question.get_new_answer()

    {flash_type, flash_msg, score, attempt, answer, wager} =
      cond do
        event_info.correct ->
          highest_score = highest_score(event_info)
          {:info, "Correct!", highest_score, 1, new_answer, event_info.wager}

        event_info.attempt < 5 ->
          {:error, "Incorrect.", socket.assigns.score, event_info.attempt + 1,
           socket.assigns.answer, event_info.wager}

        event_info.attempt >= 5 and event_info.current_score <= 0 ->
          {:error, "Out of Points, resetting.", 10, 1, new_answer, 1}

        event_info.attempt >= 5 ->
          {:error, "Out of Guesses.", event_info.current_score, 1, new_answer,
           min(event_info.wager, event_info.current_score)}
      end

    socket =
      socket
      |> clear_flash()
      |> assign(score: score, attempt: attempt, answer: answer, wager: wager)
      |> assign(form: to_form(%{}))
      |> put_flash(flash_type, flash_msg)

    {:noreply, socket}
  end

  @impl true
  def handle_event("exit", params, socket) do
    ScoreHandler.save_score(socket, params)
  end

  @impl true
  def handle_event("set_max_wager", _params, socket) do
    {:noreply, assign(socket, :wager, socket.assigns.score)}
  end

  def highest_score(event_info), do: max(event_info.current_score, event_info.highest_score)
end
