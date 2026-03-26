defmodule GameSiteWeb.MathLive do
  use GameSiteWeb, :live_view

  alias GameSiteWeb.Live.MathLive.{Component, Question}
  alias GameSiteWeb.Live.Component, as: LiveComponent
  alias GameSiteWeb.WagerFunctions, as: Helper
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
    <Component.instructions />
    <LiveComponent.score_board highest_score={@highest_score} current_score={@score} />
    <Component.question question={@question} />

    <.simple_form
      id="answer-form"
      for={@form}
      phx-submit="answer"
      class="bg-white shadow-md rounded p-4 space-y-4"
    >
      <div class="flex gap-4">
        <.input type="number" field={@form[:guess]} label="Your Guess" value="" class="flex-1" />
        <.input
          type="number"
          field={@form[:wager]}
          label="Wager"
          min="1"
          max={@score}
          value={@wager}
          class="flex-1"
        />
      </div>

      <:actions>
        <.button class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded shadow">
          Answer
        </.button>
      </:actions>
    </.simple_form>

    <Component.helper_board helper={@helper} toggle={@toggle} />

    <LiveComponent.score_submit
      form={@form}
      game_id={2}
      score={@highest_score}
      current_user={@current_user}
    />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      question = Question.get_new_question()

      socket =
        socket
        |> assign(:question, question.question)
        |> assign(:answer, question.answer)
        |> assign(:variables, question.variables)
        |> assign(:score, 10)
        |> assign(:highest_score, 0)
        |> assign(:wager, 1)
        |> assign(:form, to_form(%{"guess" => "", "wager" => 1}))
        |> assign(:helper, Question.get_helper(question.variables))
        |> assign(:toggle, true)
        |> push_event("focus-guess", %{})

      {:ok, socket}
    else
      {:ok,
       socket
       |> assign(:question, "Loading...")
       |> assign(:answer, nil)
       |> assign(:variables, nil)
       |> assign(:score, 10)
       |> assign(:highest_score, 0)
       |> assign(:wager, 1)
       |> assign(:helper, @helper_start)
       |> assign(:toggle, false)
       |> assign(:form, to_form(%{"guess" => ""}))
       |> push_event("focus-guess", %{})}
    end
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    {:noreply, assign(socket, toggle: !socket.assigns.toggle)}
  end

  @impl true
  def handle_event("answer", %{"guess" => guess, "wager" => wager}, socket) do
    correct = Helper.correct?(guess, socket.assigns.answer)
    wager = Helper.wager_parse(wager)

    new_score =
      if correct,
        do: socket.assigns.score + wager,
        else: socket.assigns.score - wager

    question = Question.get_new_question()

    flash_type = if correct, do: :info, else: :error
    flash_message = if correct, do: "Correct!", else: "Incorrect"

    put_flash(socket, flash_type, flash_message)

    socket =
      socket
      |> assign(:score, max(new_score, 0))
      |> assign(:highest_score, max(socket.assigns.highest_score, new_score))
      |> assign(:question, question.question)
      |> assign(:answer, question.answer)
      |> assign(:variables, question.variables)
      |> assign(:helper, Question.get_helper(question.variables))
      |> assign(:wager, min(wager, new_score))
      |> assign(:form, to_form(%{"guess" => "", "wager" => wager}))
      |> push_event("focus-guess", %{})

    socket =
      if new_score <= 0 do
        put_flash(socket, :error, "Score is 0 Resetting") |> assign(:score, 10)
      else
        put_flash(socket, flash_type, flash_message)
      end

    {:noreply, socket}
  end

  def handle_event("exit", params, socket) do
    ScoreHandler.save_score(socket, params)
  end
end
