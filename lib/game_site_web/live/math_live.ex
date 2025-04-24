defmodule GameSiteWeb.MathLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores
  alias GameSiteWeb.HelperFunctions, as: Helper

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
      <%!-- I might want to add in phx-hook="FocusGuess below if I get the hook working properly" --%>
      <.input type="number" field={@form[:guess]} label="Guess" value="" />
      <.input type="number" field={@form[:wager]} label="Wager" min="1" max={@score} value={@wager} />
      <:actions>
        <.button>Answer</.button>
      </:actions>
    </.simple_form>

    <%!-- <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
      <div id="flash" phx-hook="AutoDismiss" class="flash-info transition-opacity duration-500">
        {msg}
      </div>
    <% end %> --%>

    <div>
      <p>
        Here is a helper function for the current problem you are working on.<br />
        If you want to see it or turn it off just toggle the helper button below.<br />
      </p>
      <label class="toggle-switch" phx-click="toggle">
        <input type="checkbox" class="toggle-switch-check" checked={@toggle} readonly />
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
          <br /><br /><br /><br /><br /><br />
        </div>
      <% end %>
    </div>

    <div>
      This is a simple Math game that will ask you to solve a simple Math question. It will involve 2
      digits that are between 1 and 100 and an operand. You will continue to acquire points equal to the wager
      that you set for every correct answer, but you will lose the wagered points for an incorrect answer.
      If your score drops to 0 the session will be reset. You can at any point exit and save your high score.
      It will not allow you to come back to a previous session.<br /><br />#TODO: <br />Fix CSS
    </div>

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
    if connected?(socket) do
      question = new_question()

      socket =
        socket
        |> assign(:question, question.question)
        |> assign(:answer, question.answer)
        |> assign(:variables, question.variables)
        |> assign(:score, 10)
        |> assign(:highest_score, 0)
        |> assign(:wager, 1)
        |> assign(:form, to_form(%{"guess" => "", "wager" => 1}))
        |> assign(:helper, get_helper(question.variables))
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

  def handle_event("toggle", _params, socket) do
    {:noreply, assign(socket, toggle: !socket.assigns.toggle)}
  end

  def handle_event("answer", %{"guess" => guess, "wager" => wager}, socket) do
    correct = Helper.correct?(guess, socket.assigns.answer)
    wager = Helper.wager_parse(wager)

    new_score =
      if correct,
        do: socket.assigns.score + wager,
        else: socket.assigns.score - wager

    question = new_question()

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
      |> assign(:helper, get_helper(question.variables))
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
    answer = get_answer(question) |> to_string()
    %{variables: variables, question: question, answer: answer}
  end

  defp get_helper(variables) do
    first = tens_ones(variables.first)
    second = tens_ones(variables.second)
    notation = variables.notation

    case notation do
      "*" ->
        %{
          first: "#{first.tens} * #{second.tens} =",
          second: "#{first.tens} * #{second.ones} =",
          third: "#{second.tens} * #{first.ones} =",
          fourth: "#{second.ones} * #{first.ones} ="
        }

      "+" ->
        %{
          first: "#{first.tens} + #{second.tens} =",
          second: "#{first.ones} + #{second.ones} =",
          third: " ",
          fourth: " "
        }

      "-" ->
        if variables.first > variables.second do
          %{
            first: "#{first.tens} - #{second.tens} =",
            second: "#{first.ones} - #{second.ones} =",
            third: "If second ones > first ones, borrow from tens.",
            fourth: " "
          }
        else
          %{
            first: "#{second.tens} - #{first.tens} =",
            second: "#{second.ones} - #{first.ones} =",
            third: "If second ones > first ones, borrow from tens.",
            fourth: "Don't forget the sign."
          }
        end
    end
  end

  defp tens_ones(value), do: %{tens: div(value, 10) * 10, ones: rem(value, 10)}

  defp save_score(socket, :new, score_params) do
    case Scores.create_score(score_params) do
      {:ok, score} ->
        notify_parent({:new, score})

        {:noreply,
         socket |> put_flash(:info, "Score created successfully") |> push_navigate(to: "/scores")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:duplicate, :already_exists} ->
        {:noreply,
         socket |> put_flash(:info, "No new High Score") |> push_navigate(to: "/scores")}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
