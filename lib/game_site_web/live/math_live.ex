defmodule GameSiteWeb.MathLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores
  alias GameSiteWeb.HelperFunctions, as: Helper

  def render(assigns) do
    ~H"""
    <p>Highest Score: {@highest_score}</p>
    <p>Score: {@score}</p>
    <p>Question: {@question}</p>
    <.simple_form id="answer-form" for={@form} phx-submit="answer">
      <.input type="hidden" field={@form[:question]} value={@question} />
      <.input type="hidden" field={@form[:answer]} value={@answer} />
      <.input
        type="number"
        field={@form[:guess]}
        label="Guess"
        phx-hook="FocusGuess"
        value={@guess}
      />
      <.input
        type="number"
        field={@form[:wager]}
        label="Wager"
        min="1"
        max={@score}
        value={@wager}
      />
      <:actions>
        <.button>Answer</.button>
      </:actions>
    </.simple_form>

    <body>
      <div>
        This is a simple Math game that will ask you to solve a simple Math question. It will involve 2
        digits that are between 1 and 100 and an operand. You will continue to acquire points equal to the wager
        that you set for every correct answer, but you will lose the wagered points for an incorrect answer.
        If your score drops to 0 the session will be reset. You can at any point exit and save your high score.
        It will not allow you to come back to a previous session.<br />
        <br />
        <br />#todo: <br />Fix issue with the first mount not being the right question.
      </div>
    </body>
    <.simple_form id="exit-form" for={@form} phx-submit="exit">
      <.input type="hidden" field={@form[:user_id]} value={@current_user.id} />
      <.input type="hidden" field={@form[:game_id]} value={2} />
      <.input type="hidden" field={@form[:score]} value={@score} />
      <:actions>
        <.button>Exit and Save Score</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      new_q =
        new_question()
        |> IO.inspect(label: "First Question")

      form =
        to_form(%{
          "guess" => "",
          "wager" => 1,
          "question" => new_q.question,
          "answer" => new_q.answer
        })

      socket =
        assign(socket,
          question: new_q.question,
          answer: new_q.answer,
          variables: new_q.variables,
          score: 10,
          form: form,
          highest_score: 0,
          wager: 1,
          guess: ""
        )

      {:ok, socket}
    else
      socket =
        assign(socket,
          question: "Loading...",
          answer: nil,
          variables: nil,
          score: 10,
          form: to_form(%{"guess" => ""}),
          highest_score: 0,
          wager: 1,
          guess: ""
        )

      {:ok, socket}
    end
  end

  # Generate the question once the websocket is connected
  def handle_info(:generate_question, socket) do
    new_question =
      new_question()
      |> IO.inspect(label: "First Question")

    form =
      to_form(%{
        "guess" => "",
        "wager" => socket.assigns.wager,
        "question" => new_question.question,
        "answer" => new_question.answer
      })

    {:noreply,
     assign(socket,
       question: new_question.question,
       answer: new_question.answer,
       variables: new_question.variables,
       form: form
     )}
  end

  def handle_event("answer", params, socket) do
    event_info =
      set_event_info(socket, params)
      |> IO.inspect(label: "Event Info")

    new_question =
      new_question()
      |> IO.inspect(label: "New Question")

    cond do
      event_info.correct ->
        question_assigns = Map.take(new_question, ~w[question answer variables]a)
        highest_score = Helper.highest_score(event_info)
        answer_form = to_form(%{"guess" => "", "wager" => event_info.wager})

        socket =
          socket
          |> push_event("focus-guess", %{})
          |> assign(question_assigns)
          |> assign(:score, event_info.current_score)
          |> assign(:highest_score, highest_score)
          |> assign(:wager, event_info.wager)
          |> assign(:form, answer_form)
          |> assign(:guess, "")

        {:noreply, socket}

      event_info.current_score == 0 ->
        socket =
          assign(
            socket
            |> put_flash(:info, "Score is 0 Resetting")
            |> push_event("focus-guess", %{}),
            question: new_question.question,
            answer: new_question.answer,
            variables: new_question.variables,
            score: 10,
            wager: event_info.wager,
            form: to_form(%{"guess" => "", "wager" => event_info.wager})
          )

        {:noreply, socket}

      event_info.correct == false ->
        socket =
          assign(
            socket
            |> put_flash(:info, "Incorrect")
            |> push_event("focus-guess", %{}),
            question: new_question.question,
            answer: new_question.answer,
            variables: new_question.variables,
            score: event_info.current_score,
            highest_score: Helper.highest_score(event_info),
            wager: min(event_info.wager, event_info.current_score),
            form: to_form(%{"guess" => "", "wager" => event_info.wager})
          )

        {:noreply, socket}
    end
  end

  def handle_event("exit", params, socket) do
    save_score(socket, :new, params)
  end

  defp new_variables() do
    %{
      first: Enum.random(1..100),
      second: Enum.random(1..100),
      notation: Enum.random(["+", "-", "*"])
    }
  end

  defp get_answer(question) do
    {answer, _} = Code.eval_string(question)
    answer
  end

  defp get_question(%{first: first, second: second, notation: notation}) do
    "#{first} #{notation} #{second}"
  end

  defp new_question() do
    variables = new_variables()
    question = get_question(variables)

    answer =
      get_answer(question)
      |> to_string()

    %{variables: variables, question: question, answer: answer}
  end

  defp set_event_info(socket, %{"wager" => wager, "guess" => guess, "answer" => answer}) do
    parsed_wager =
      Helper.add_subtract_wager(wager, guess, answer)

    %{
      current_score: socket.assigns.score + parsed_wager,
      highest_score: socket.assigns.highest_score,
      guess: guess,
      wager: wager,
      correct: guess == answer
    }
  end

  defp save_score(socket, :new, score_params) do
    case Scores.create_score(score_params) do
      {:ok, score} ->
        notify_parent({:new, score})

        {:noreply,
         socket
         |> put_flash(:info, "Score created successfully")
         |> push_navigate(to: "/scores")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:duplicate, :already_exists} ->
        {:noreply,
         socket
         |> put_flash(:info, "No new High Score")
         |> push_navigate(to: "/scores")}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
