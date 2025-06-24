defmodule GameSiteWeb.MathLive do
  use GameSiteWeb, :live_view

  import GameSiteWeb.LoginHelpers
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
    <%!-- <div class="max-w-xl mx-auto space-y-6 p-4 text-gray-800"> --%>
    <section class="bg-gray-50 rounded p-4 shadow">
      <h2 class="text-xl font-semibold mb-2">Math Game Overview</h2>
      <ul class="list-disc list-inside mt-2 space-y-1 text-gray-700">
        <li>Each round presents a basic math equation using numbers from 1 to 100.</li>
        <li>Before answering, you choose how many points to wager.</li>
        <li>If your answer is correct, you gain the wagered points.</li>
        <li>If you're wrong, the wager is subtracted from your score.</li>
        <li>When your score reaches 0, the game resets—but your highest score is saved.</li>
        <li>The goal is to maintain a streak and beat your personal best!</li>
      </ul>

      <div class="mt-4 flex justify-center gap-8 text-center font-semibold text-gray-800">
        <div>
          <div class="text-sm text-gray-500">Highest Score</div>
          <div>{@highest_score}</div>
        </div>
        <div>
          <div class="text-sm text-gray-500">Current Score</div>
          <div>{@score}</div>
        </div>
      </div>
    </section>
    <section class="bg-gray-50 rounded p-4 shadow text-center">
      <div>
        <div class="text-sm text-gray-500">Question</div>
        <div>{@question}</div>
      </div>
    </section>

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

    <div class="bg-white shadow-md rounded p-4 space-y-4 border border-gray-300 h-64">
      <p>
        Toggle the helper function if you want a hint or want to hide it:
      </p>
      <label class="flex items-center space-x-2 cursor-pointer" phx-click="toggle">
        <input type="checkbox" class="sr-only" checked={@toggle} readonly />
        <div class="w-10 h-5 bg-gray-300 rounded-full relative">
          <div class={"w-5 h-5 bg-white rounded-full shadow absolute top-0 transition-transform #{if @toggle, do: "translate-x-5", else: "translate-x-0"}"}>
          </div>
        </div>
        <span>Show Helper</span>
      </label>

      <div class={if @toggle, do: "", else: "invisible"}>
        <p>{@helper.first}</p>
        <p>{@helper.second}</p>
        <p>{@helper.third}</p>
        <p>{@helper.fourth}</p>
      </div>
    </div>

    <div class="bg-white shadow-md rounded p-4">
      <p>
        <%= if not logged_in?(@socket.assigns) do %>
          <br /> <br />If you want to submit your score please make an
          <a
            href="/users/register"
            style="cursor: pointer; text-decoration: none; color: blue;"
            onmouseover="this.style.textDecoration='underline'; this.style.color='red';"
            onmouseout="this.style.textDecoration='none'; this.style.color='blue';"
          >
            account
          </a>
        <% end %>
      </p>
    </div>
    <%= if logged_in?(@socket.assigns) do %>
      <.simple_form
        id="exit-form"
        for={@form}
        phx-submit="exit"
        class="bg-white shadow-md rounded p-4"
      >
        <.input type="hidden" field={@form[:user_id]} value={@current_user.id} />
        <.input type="hidden" field={@form[:game_id]} value={2} />
        <.input type="hidden" field={@form[:score]} value={@highest_score} />
        <:actions>
          <.button class="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded shadow">
            Exit and Save Score
          </.button>
        </:actions>
      </.simple_form>
    <% end %>
    <%!-- </div> --%>
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
