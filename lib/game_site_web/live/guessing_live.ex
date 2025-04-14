defmodule GameSiteWeb.GuessingLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores
  alias GameSiteWeb.HelperFunctions, as: Helper

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
        value={@wager}
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
       score: 10,
       wager: 1
     )}
  end

  def handle_event("answer", %{"guess" => guess, "wager" => wager}, socket) do
    parsed_wager =
      Helper.parse_wager(wager)
      |> Helper.add_subtract_wager(guess, to_string(socket.assigns.answer))

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
        highest_score = Helper.highest_score(event_info)

        {:noreply,
         assign(
           socket
           |> put_flash(:info, "Correct!"),
           answer: new_answer(),
           score: event_info.current_score,
           attempt: 1,
           highest_score: highest_score,
           wager: wager
         )}

      event_info.attempt < 5 ->
        {:noreply,
         assign(
           socket
           |> put_flash(:info, "Incorrect."),
           attempt: event_info.attempt + 1,
           wager: wager
         )}

      event_info.attempt >= 5 and event_info.current_score == 0 ->
        {:noreply,
         socket
         |> put_flash(:info, "Out of Points, resetting.")
         |> assign(
           attempt: 1,
           score: 10,
           answer: new_answer(),
           wager: 1
         )}

      event_info.attempt >= 5 ->
        {:noreply,
         socket
         |> put_flash(:info, "Out of Guesses.")
         |> assign(
           attempt: 1,
           score: event_info.current_score,
           answer: new_answer(),
           wager: min(wager, event_info.current_score)
         )}
    end
  end

  def handle_event("exit", params, socket) do
    save_score(socket, :new, params)
  end

  defp new_answer(), do: Enum.random(1..10)

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
