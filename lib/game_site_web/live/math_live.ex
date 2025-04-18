defmodule GameSiteWeb.MathLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores
  alias GameSiteWeb.HelperFunctions, as: Helper
  # alias Ecto.Changeset

  # import Ecto.Changeset

  # @types %{guess: :integer, wager: :integer, question: :string, answer: :integer}
  # @default %{guess: nil, wager: 1, question: nil, answer: nil}

  @helper_start %{
    first: "Loading...",
    second: "Loading...",
    third: "Loading...",
    fourth: "Loading..."
  }

  def render(assigns) do
    ~H"""
    <p>Highest Score: {@highest_score}</p>
    <p>Score: {@score}</p>
    <p>Question: {@question}</p>
    <.simple_form id="answer-form" for={@form} phx-submit="answer">
      <.input type="hidden" field={@form[:question]} value={@question} />
      <.input type="hidden" field={@form[:answer]} value={@answer} />
      <.input type="number" field={@form[:guess]} label="Guess" phx-hook="FocusGuess" key={@question} />
      <.input type="number" field={@form[:wager]} label="Wager" min="1" max={@score} value={@wager} />
      <:actions>
        <.button>Answer</.button>
      </:actions>
    </.simple_form>

    <div>
      <p>
        Here is a helper function for the current problem you are working on.<br />
        If you want to see it or turn it off just toggle the helper button below.<br />
      </p>
      <label class="toggle-switch" phx-click="toggle">
        <input type="checkbox" class="toggle-switch-check" phx-click="toggle" checked={@toggle} />
        <span aria-hidden="true" class="toggle-switch-bar">
          <span class="toggle-switch-handle"></span>
        </span>
      </label>
      <%= if @toggle do %>
        <div style="white-space: pre; font-family: monospace;">
          <p>{@helper.first}</p>
          <p>{@helper.second}</p>
          <p>{@helper.third}</p>
          <p>{@helper.fourth}</p>
        </div>
      <% else %>
        <div style="white-space: pre; font-family: monospace;">
          <br />
          <br />
          <br />
          <br />
          <br />
          <br />
        </div>
      <% end %>
    </div>

    <body>
      <div>
        This is a simple Math game that will ask you to solve a simple Math question. It will involve 2
        digits that are between 1 and 100 and an operand. You will continue to acquire points equal to the wager
        that you set for every correct answer, but you will lose the wagered points for an incorrect answer.
        If your score drops to 0 the session will be reset. You can at any point exit and save your high score.
        It will not allow you to come back to a previous session.<br />
        <br />
        <br />#TODO: <br />Fix CSS
      </div>
    </body>
    <.simple_form id="exit-form" for={@form} phx-submit="exit">
      <.input type="hidden" field={@form[:user_id]} value={@current_user.id} />
      <.input type="hidden" field={@form[:game_id]} value={2} />
      <.input type="hidden" field={@form[:score]} value={@highest_score} />
      <:actions>
        <.button>Exit and Save Score</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    form =
      to_form(%{
        "guess" => "",
        "wager" => 1
      })

    if connected?(socket) do
      new_question =
        new_question()
        |> IO.inspect(label: "First Question")

      question_assigns = Map.take(new_question, ~w[question answer variables]a)

      socket =
        socket
        |> assign(question_assigns)
        |> assign(score: 10)
        |> assign(highest_score: 0)
        |> assign(wager: 1)
        |> assign(form: form)
        |> assign(helper: get_helper(question_assigns.variables))
        |> assign(toggle: true)
        |> push_event("focus-guess", %{})

      {:ok, socket}
    else
      socket =
        socket
        |> assign(question: "Loading...")
        |> assign(answer: nil)
        |> assign(variables: nil)
        |> assign(score: 10)
        |> assign(highest_score: 0)
        |> assign(wager: 1)
        |> assign(helper: @helper_start)
        |> assign(toggle: false)
        |> assign(form: to_form(%{"guess" => ""}))
        |> push_event("focus-guess", %{})

      # send(self(), :generate_question)
      {:ok, socket}
    end
  end

  # def handle_info(:generate_question, socket) do
  #   new_question =
  #     new_question()
  #     |> IO.inspect(label: ":generate_question Question")

  #   question_assigns = Map.take(new_question, ~w[question answer variables]a)

  #   socket =
  #     socket
  #     |> assign(question_assigns)

  #   {:noreply, socket}
  # end

  # def handle_event("toggle", _params, socket) do
  #   toggle = not socket.assigns.toggle
  #   {:noreply, assign(socket, toggle: toggle)}
  # end

  def handle_event("toggle", %{"toggle-switch-check" => "on"}, socket) do
    IO.inspect(socket.assigns.question, label: "Toggle ON — Question")
    IO.inspect(socket.assigns.answer, label: "Toggle ON — Answer")
    {:noreply, assign(socket, toggle: true)}
  end

  def handle_event("toggle", _params, socket) do
    IO.inspect(socket.assigns.question, label: "Toggle OFF — Question")
    IO.inspect(socket.assigns.answer, label: "Toggle OFF — Answer")
    {:noreply, assign(socket, toggle: false)}
  end

  def handle_event("answer", params, socket) do
    event_info =
      set_event_info(socket, params)
      |> IO.inspect(label: "Event Info")

    new_question =
      new_question()
      |> IO.inspect(label: "New Question")

    question_assigns = Map.take(new_question, ~w[question answer variables]a)
    answer_form = to_form(%{"guess" => "", "wager" => event_info.wager})

    cond do
      event_info.correct ->
        highest_score = Helper.highest_score(event_info)

        socket =
          socket
          |> assign(question_assigns)
          |> assign(:score, event_info.current_score)
          |> assign(:highest_score, highest_score)
          |> assign(:wager, event_info.wager)
          |> assign(:form, answer_form)
          |> assign(helper: get_helper(question_assigns.variables))
          |> push_event("focus-guess", %{})

        {:noreply, socket}

      event_info.current_score <= 0 ->
        socket =
          socket
          |> assign(question_assigns)
          |> assign(:score, 10)
          |> assign(:wager, event_info.wager)
          |> assign(:form, answer_form)
          |> assign(helper: get_helper(question_assigns.variables))
          |> put_flash(:error, "Score is 0 Resetting")
          |> push_event("focus-guess", %{})

        {:noreply, socket}

      event_info.correct == false ->
        socket =
          socket
          |> assign(question_assigns)
          |> assign(:score, event_info.current_score)
          |> assign(:wager, min(event_info.wager, event_info.current_score))
          |> assign(:form, answer_form)
          |> assign(helper: get_helper(question_assigns.variables))
          |> put_flash(:error, "Incorrect")
          |> push_event("focus-guess", %{})

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

  defp get_helper(variables) do
    first = tens_ones(variables.first)
    second = tens_ones(variables.second)
    notation = variables.notation

    case notation do
      "*" ->
        %{
          first:
            "#{String.pad_leading("#{first.tens}", 2)} #{notation} #{String.pad_leading("#{second.tens}", 2)} =",
          second:
            "#{String.pad_leading("#{first.tens}", 2)} #{notation} #{String.pad_leading("#{second.ones}", 2)} =",
          third:
            "#{String.pad_leading("#{second.tens}", 2)} #{notation} #{String.pad_leading("#{first.ones}", 2)} =",
          fourth:
            "#{String.pad_leading("#{second.ones}", 2)} #{notation} #{String.pad_leading("#{first.ones}", 2)} ="
        }

      "+" ->
        %{
          first:
            "#{String.pad_leading("#{first.tens}", 2)} #{notation} #{String.pad_leading("#{second.tens}", 2)} =",
          second:
            "#{String.pad_leading("#{first.ones}", 2)} #{notation} #{String.pad_leading("#{second.ones}", 2)} =",
          third: " ",
          fourth: " "
        }

      "-" ->
        if variables.first > variables.second do
          %{
            first:
              "#{String.pad_leading("#{first.tens}", 2)} #{notation} #{String.pad_leading("#{second.tens}", 2)} =",
            second:
              "#{String.pad_leading("#{first.ones}", 2)} #{notation} #{String.pad_leading("#{second.ones}", 2)} =",
            third:
              "If the second ones is greater than the first ones borrow from the first answer.",
            fourth: " "
          }
        else
          %{
            first:
              "#{String.pad_leading("#{second.tens}", 2)} #{notation} #{String.pad_leading("#{first.tens}", 2)} =",
            second:
              "#{String.pad_leading("#{second.ones}", 2)} #{notation} #{String.pad_leading("#{first.ones}", 2)} =",
            third:
              "If the second ones is greater than the first ones borrow from the first answer.",
            fourth: "Don't forget the sign."
          }
        end
    end
  end

  defp tens_ones(value), do: %{tens: div(value, 10) * 10, ones: rem(value, 10)}

  defp set_event_info(socket, %{
         "wager" => wager,
         "guess" => guess,
         "answer" => answer
       }) do
    parsed_wager =
      Helper.add_subtract_wager(wager, guess, answer)

    %{
      current_score: socket.assigns.score + parsed_wager,
      highest_score: socket.assigns.highest_score,
      guess: guess,
      wager: String.to_integer(wager),
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
