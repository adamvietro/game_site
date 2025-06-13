defmodule GameSiteWeb.GuessingLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores
  alias GameSiteWeb.HelperFunctions, as: Helper

  def render(assigns) do
    ~H"""
    <div class="text-center space-y-2">
      <p class="text-lg font-semibold">Session High Score: {@highest_score}</p>
      <p class="text-lg">Score: {@score}</p>
      <p class="text-md text-gray-600">Attempt: {@attempt}</p>
    </div>

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

    <div class="bg-gray-50 p-4 rounded shadow text-sm text-gray-700">
      <p>
        <strong>Game Info:</strong>
        <br />
        This is a simple Guessing Game. The site picks a random number between 1 and 10. You have 5 chances
        to guess correctly. You can change your wager amount, but dropping to 0 points will reset your session.
        Exiting will save your high score, but you won’t be able to resume this streak later.
      </p>
    </div>
    <.simple_form id="exit-form" for={@form} phx-submit="exit" class="text-center">
      <.input type="hidden" field={@form[:user_id]} value={@current_user.id} />
      <.input type="hidden" field={@form[:game_id]} value={1} />
      <.input type="hidden" field={@form[:score]} value={@highest_score} />
      <:actions>
        <.button class="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded shadow">
          Exit and Save Score
        </.button>
      </:actions>
    </.simple_form>
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
