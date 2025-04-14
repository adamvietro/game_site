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
      <.input type="number" field={@form[:guess]} label="Guess" value={@form.params["guess"]} />
      <.input
        type="number"
        field={@form[:wager]}
        label="Wager"
        value={@form.params["wager"]}
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
    # Set placeholders initially
    socket =
      assign(socket,
        # Placeholder for question
        question: "Loading...",
        # No answer yet
        answer: nil,
        # No variables yet
        variables: nil,
        score: 10,
        form: to_form(%{"guess" => ""}),
        highest_score: 10,
        wager: 1
      )

    if connected?(socket) do
      # Once connected, generate the real question
      send(self(), :generate_question)
    end

    {:ok, socket}
  end

  # Generate the question once the websocket is connected
  def handle_info(:generate_question, socket) do
    variables = new_variables()
    question = get_question(variables)
    {answer, _} = Code.eval_string(question)

    {:noreply,
     assign(socket,
       question: question,
       answer: to_string(answer),
       variables: variables
     )}
  end

  def handle_event("answer", params, socket) do
    event_info =
      set_event_info(socket, params)

    cond do
      event_info.correct ->
        variables = new_variables()
        question = get_question(variables)
        {answer, _} = Code.eval_string(question)

        {:noreply,
         assign(socket,
           question: question,
           answer: to_string(answer),
           score: event_info.current_score,
           form: to_form(%{"guess" => ""}),
           variables: variables,
           highest_score: Helper.highest_score(event_info),
           wager: event_info.wager
         )}

      event_info.current_score == 0 ->
        variables = new_variables()
        question = get_question(variables)
        {answer, _} = Code.eval_string(question)

        {:noreply,
         assign(
           socket
           |> put_flash(:info, "0 Score resetting."),
           question: question,
           answer: to_string(answer),
           score: 10,
           form: to_form(%{"guess" => ""}),
           variables: variables
         )}

      event_info.correct == false ->
        variables = new_variables()
        question = get_question(variables)
        {answer, _} = Code.eval_string(question)

        {:noreply,
         assign(
           socket
           |> put_flash(:info, "Incorrect."),
           question: question,
           answer: to_string(answer),
           score: event_info.current_score,
           form: to_form(%{"guess" => ""}),
           variables: variables,
           highest_score: Helper.highest_score(event_info),
           wager: event_info.wager
         )}
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

  defp set_event_info(socket, params) do
    parsed_wager =
      Helper.add_subtract_wager(
        String.to_integer(params["wager"]),
        params["guess"],
        socket.assigns.answer
      )

    %{
      question: socket.assigns.question,
      answer: socket.assigns.answer,
      current_score: socket.assigns.score + parsed_wager,
      variables: socket.assigns.variables,
      highest_score: socket.assigns.highest_score,
      guess: params["guess"],
      wager: String.to_integer(params["wager"]),
      score: socket.assigns.score,
      correct: params["guess"] == socket.assigns.answer
    }
  end

  defp get_question(%{first: first, second: second, notation: notation}) do
    "#{first} #{notation} #{second}"
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
