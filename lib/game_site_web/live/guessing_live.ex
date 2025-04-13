defmodule GameSiteWeb.GuessingLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores

  def render(assigns) do
    ~H"""
    <p>Session High Score: {@highest_score}</p>
    <p>Score: {@score}</p>
    <p>Attempt: {@attempt}</p>
    <%!-- <p>Answer: {@answer}</p> --%>

    <div class="grid grid-cols-5 gap-x-3 gap-y-1 max-w-md mx-auto mt-4">
      <%= for guess <- 1..10 do %>
        <.simple_form for={@form} phx-submit="answer" class="text-center">
          <.input type="hidden" field={@form[:guess]} value={guess} />
          <input type="hidden" name="wager" id={"wager_hidden_#{guess}"} />

          <.button type="submit" class="w-full" phx-hook="CopyBonus">
            {guess}
          </.button>
        </.simple_form>
      <% end %>
    </div>

    <div class="max-w-md mx-auto mt-4">
      <label for="bonus_input" class="block text-sm font-medium text-gray-700 mb-1">
        Wager
      </label>
      <input
        type="number"
        id="wager_input"
        name="wager_visible"
        min="1"
        value="1"
        max={@score}
        step="1"
        class="w-full rounded-md border-gray-300 shadow-sm"
      />
    </div>

    <body>
      <div>
        <br /> This is a simple Guessing Game. The site will pick a random number between 1 and 10 and
        you will have 5 guesses to get the correct answer. At any point you can exit and save your high score,
        you will not be able to come back to your streak. You can change the amount of points you want to wager,
        but if ever reach a point score of 0 you will be reset to the initial state.
        <br /><br />#TODO: <br />Fix the CSS
      </div>
    </body>
    <.simple_form id="exit-form" for={@form} phx-submit="exit">
      <.input type="hidden" field={@form[:user_id]} value={@current_user.id} />
      <.input type="hidden" field={@form[:game_id]} value={1} />
      <.input type="hidden" field={@form[:score]} value={@highest_score} />
      <:actions>
        <.button>Exit and Save Score</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    new_answer =
      new_answer()

    {:ok,
     assign(
       socket,
       answer: new_answer,
       attempt: 1,
       form: to_form(%{"guess" => ""}),
       highest_score: 0,
       score: 10
     )}
  end

  def handle_event("answer", %{"guess" => guess, "wager" => wager}, socket) do
    parsed_wager =
      parse_wager(wager)
      |> add_subtract_wager(guess, to_string(socket.assigns.answer))

    event_info =
      %{
        score: socket.assigns.score,
        attempt: socket.assigns.attempt,
        highest_score: socket.assigns.highest_score,
        answer: to_string(socket.assigns.answer),
        guess: guess,
        wager: parsed_wager,
        current_score: socket.assigns.score + parsed_wager
      }

    cond do
      event_info.answer == event_info.guess ->
        highest_score = highest_score(event_info)

        {:noreply,
         assign(
           socket
           |> put_flash(:info, "Correct!"),
           answer: new_answer(),
           score: event_info.current_score,
           attempt: 1,
           highest_score: highest_score
         )}

      event_info.attempt < 5 ->
        {:noreply,
         assign(
           socket
           |> put_flash(:info, "Incorrect."),
           attempt: event_info.attempt + 1
         )}

      event_info.attempt >= 5 and event_info.current_score == 0 ->
        {:noreply,
         socket
         |> put_flash(:info, "Out of Points, resetting.")
         |> assign(
           attempt: 1,
           score: 10,
           answer: new_answer()
         )}

      event_info.attempt >= 5 ->
        {:noreply,
         socket
         |> put_flash(:info, "Out of Guesses.")
         |> assign(
           attempt: 1,
           score: event_info.current_score,
           answer: new_answer()
         )}
    end
  end

  def handle_event("exit", params, socket) do
    save_score(socket, :new, params)
  end

  defp highest_score(event_info), do: max(event_info.current_score, event_info.highest_score)

  defp new_answer(), do: Enum.random(1..10)

  defp parse_wager(nil), do: 1
  defp parse_wager(""), do: 1

  defp parse_wager(wager) do
    case Integer.parse(wager) do
      {int, _} -> int
      :error -> 1
    end
  end

  defp add_subtract_wager(wager, guess, answer) do
    if guess == answer do
      wager
    else
      wager * -1
    end
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
