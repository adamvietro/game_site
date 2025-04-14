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
        digits that are between 1 and 100 and an operand. You will continue to acquire a single point for every
        correct answer that you give. You can at any point exit and save your high score, however 1 incorrect answer
        will reduce your score to 0. It will not allow you to come back to a previous session.<br />
        <br />
        <br />#todo: <br />Add a wager button (for more points)
        <br />Add a param for highest score for the session <br />Change it to any size of questions
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
        question: "Loading...",  # Placeholder for question
        answer: nil,              # No answer yet
        variables: nil,           # No variables yet
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

    if event_info.guess == event_info.answer do
      variables = new_variables()
      question = get_question(variables)
      {answer, _} = Code.eval_string(question)

      {:noreply,
       assign(socket,
         question: question,
         answer: to_string(answer),
         score: socket.assigns.score + event_info.wager,
         form: to_form(%{"guess" => ""}),
         variables: variables,
         highest_score: Helper.highest_score(event_info),
         wager: event_info.wager
       )}
    else
      variables = new_variables()
      question = get_question(variables)
      {answer, _} = Code.eval_string(question)

      {:noreply,
       assign(
         socket
         |> put_flash(:info, "Incorrect resetting."),
         question: question,
         answer: to_string(answer),
         score: 10,
         form: to_form(%{"guess" => ""}),
         variables: variables
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
    %{
      question: socket.assigns.question,
      answer: socket.assigns.answer,
      current_score: socket.assigns.score,
      variables: socket.assigns.variables,
      highest_score: socket.assigns.highest_score,
      guess: params["guess"],
      wager: String.to_integer(params["wager"])
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
