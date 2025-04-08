defmodule GameSiteWeb.GuessingLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores

  def render(assigns) do
    ~H"""
    <p>Score: {@score}</p>
    <p>Question: {@question}</p>
    <.simple_form id="answer-form" for={@form} phx-submit="answer">
      <.input type="number" field={@form[:answer]} label="Answer" />
      <.input type="hidden" field={@form[:first]} value={@first} />
      <.input type="hidden" field={@form[:second]} value={@second} />
      <.input type="hidden" field={@form[:notation]} value={@notation} />
      <:actions>
        <.button>Answer</.button>
      </:actions>
    </.simple_form>

    <body>
      <div>
        This is a simple Math game that will ask you to solve a simple Math question. It will involve 2
        digits that are between 1 and 100 and a operand. You will continue to acquire a single point for every
        correct answer that you give. You can at any point exit and save your high score, however 1 incorrect answer
        will reduce your score to 0.
        <br>#todo:
        <br>add a wager button (for more points)
        <br>add a param for highest score for the session
        <br>keep only the highest 5 scores for each player
        <br>change it to any size of questions
      </div>
    </body>
    <.simple_form id="exit-form" for={@form} phx-submit="exit">
      <.input type="hidden" field={@form[:user_id]} value={@current_user.id} />
      <.input type="hidden" field={@form[:game_id]} value={1} />
      <.input type="hidden" field={@form[:score]} value={@score} />
      <:actions>
        <.button>Exit and Save Score</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    first = Enum.random(1..100)
    second = Enum.random(1..100)
    notation = Enum.random(["+", "-", "*"])

    {:ok,
     assign(socket,
       question: "#{first} #{notation} #{second}",
       score: 0,
       form: to_form(%{"answer" => ""}),
       first: first,
       second: second,
       notation: notation
     )}
  end

  def handle_event("answer", params, socket) do
    answer =
      case params["notation"] do
        "*" -> String.to_integer(params["first"]) * String.to_integer(params["second"])
        "+" -> String.to_integer(params["first"]) + String.to_integer(params["second"])
        "-" -> String.to_integer(params["first"]) - String.to_integer(params["second"])
      end

    if params["answer"] == to_string(answer) do
      first = Enum.random(1..100)
      second = Enum.random(1..100)
      notation = Enum.random(["+", "-", "*"])

      {:noreply,
       assign(socket,
         question: "#{first} #{notation} #{second}",
         score: socket.assigns.score + 1,
         form: to_form(%{"answer" => ""}),
         first: first,
         second: second,
         notation: notation
       )}
    else
      {:noreply,
       assign(socket, score: 0, form: to_form(params, errors: [answer: {"incorrect", []}]))}
    end
  end

  def handle_event("exit", params, socket) do
    save_score(socket, :new, params)
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
