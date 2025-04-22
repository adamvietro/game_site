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
          <.input type="hidden" field={@form[:guess]} value={guess} id={"guess_hidden_#{guess}"} />

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
          |> put_flash(:info, "Incorrect.")

        {:noreply, socket}

      event_info.attempt >= 5 and event_info.current_score <= 0 ->
        socket =
          socket
          |> assign(attempt: 1)
          |> assign(score: 10)
          |> assign(answer: new_answer())
          |> assign(wager: 1)
          |> assign(form: to_form(%{}))
          |> put_flash(:info, "Out of Points, resetting.")

        {:noreply, socket}

      event_info.attempt >= 5 ->
        IO.inspect([event_info.wager, event_info.current_score])

        socket =
          socket
          |> assign(attempt: 1)
          |> assign(score: event_info.current_score)
          |> assign(answer: new_answer())
          |> assign(wager: min(event_info.wager, event_info.current_score))
          |> assign(form: to_form(%{}))
          |> put_flash(:info, "Out of Guesses.")

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
