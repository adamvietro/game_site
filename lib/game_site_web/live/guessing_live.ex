defmodule GameSiteWeb.GuessingLive do
  use GameSiteWeb, :live_view

  import GameSiteWeb.LoginHelpers
  alias GameSite.Scores
  alias GameSiteWeb.HelperFunctions, as: Helper

  def render(assigns) do
    ~H"""
    <section class="bg-gray-50 rounded p-4 shadow space-y-4">
      <h2 class="text-xl font-semibold">Guessing Game Overview</h2>
      <ul class="list-disc list-inside text-left max-w-prose text-gray-700 space-y-1">
        <li>The site picks a random number between 1 and 10.</li>
        <li>You have 5 chances to guess the correct number.</li>
        <li>Adjust your wager amount before each guess.</li>
        <li>Correct guesses increase your score by the wager.</li>
        <li>Incorrect guesses decrease your score by the wager.</li>
        <li>If your score hits 0, your session resets but keeps your high score.</li>
      </ul>

      <div class="grid grid-cols-3 gap-4 text-center font-semibold text-gray-800">
        <div>
          <div class="text-sm text-gray-500">Highest Score</div>
          <div>{@highest_score}</div>
        </div>
        <div>
          <div class="text-sm text-gray-500">Current Score</div>
          <div>{@score}</div>
        </div>
        <div>
          <div class="text-sm text-gray-500">Attempt</div>
          <div>{@attempt}</div>
        </div>
      </div>
    </section>

    <div class="grid grid-cols-5 gap-x-3 gap-y-1 max-w-md mx-auto mt-4">
      <%= for guess <- 1..10 do %>
        <.simple_form for={@form} phx-submit="answer" class="text-center">
          <.input type="hidden" field={@form[:guess]} value={guess} id={"guess_hidden_#{guess}"} />

          <input type="hidden" name="wager" id={"wager_hidden_#{guess}"} />

          <.button type="submit" class="w-full" phx-hook="CopyBonus">
            {guess}
          </.button>
        </.simple_form>
      <% end %>
    </div>

    <div class="max-w-xs mx-auto">
      <label for="wager_input" class="block text-sm font-medium text-gray-700 mb-1">
        Wager
      </label>
      <input
        type="number"
        id="wager_input"
        name="wager_visible"
        min="1"
        value={@wager}
        max={@score}
        step="1"
        class="w-full rounded-md border-gray-300 shadow-sm focus:ring-blue-500 focus:border-blue-500"
      />
    </div>
    <br /> <br />

    <div class="bg-gray-50 p-4 rounded shadow text-sm text-gray-700">
      <p>
        <%= if not logged_in?(@socket.assigns) do %>
          If you want to submit your score please make an
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
      <.simple_form id="exit-form" for={@form} phx-submit="exit" class="text-center">
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
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(answer: new_answer())
      |> assign(score: 10)
      |> assign(attempt: 1)
      |> assign(highest_score: 0)
      |> assign(wager: 1)
      |> assign(form: to_form(%{}))

    {:ok, socket}
  end

  def handle_event("answer", params, socket) do
    event_info =
      set_event_info(socket, params)

    cond do
      event_info.correct ->
        highest_score = Helper.highest_score(event_info)

        socket =
          socket
          |> assign(answer: new_answer())
          |> assign(score: event_info.current_score)
          |> assign(attempt: 1)
          |> assign(highest_score: highest_score)
          |> assign(wager: event_info.wager)
          |> assign(form: to_form(%{}))
          |> put_flash(:info, "Correct!")

        {:noreply, socket}

      event_info.attempt < 5 ->
        socket =
          socket
          |> assign(attempt: event_info.attempt + 1)
          |> assign(wager: event_info.wager)
          |> assign(form: to_form(%{}))
          |> put_flash(:error, "Incorrect.")

        {:noreply, socket}

      event_info.attempt >= 5 and event_info.current_score <= 0 ->
        socket =
          socket
          |> assign(attempt: 1)
          |> assign(score: 10)
          |> assign(answer: new_answer())
          |> assign(wager: 1)
          |> assign(form: to_form(%{}))
          |> put_flash(:error, "Out of Points, resetting.")

        {:noreply, socket}

      event_info.attempt >= 5 ->
        socket =
          socket
          |> assign(attempt: 1)
          |> assign(score: event_info.current_score)
          |> assign(answer: new_answer())
          |> assign(wager: min(event_info.wager, event_info.current_score))
          |> assign(form: to_form(%{}))
          |> put_flash(:error, "Out of Guesses.")

        {:noreply, socket}
    end
  end

  def handle_event("exit", params, socket) do
    save_score(socket, :new, params)
  end

  defp new_answer(), do: Enum.random(1..10)

  defp set_event_info(socket, %{"wager" => wager, "guess" => guess}) do
    parsed_wager =
      Helper.add_subtract_wager(wager, guess, socket.assigns.answer)

    %{
      current_score: socket.assigns.score + parsed_wager,
      highest_score: socket.assigns.highest_score,
      wager: String.to_integer(wager),
      attempt: socket.assigns.attempt,
      correct: to_string(socket.assigns.answer) == guess
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
