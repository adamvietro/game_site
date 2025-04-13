defmodule GameSiteWeb.GuessingLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores

  def render(assigns) do
    ~H"""
    <p>Score: {@score}</p>
    <p>Attempt: {@attempt}</p>
    <%!-- <p>Answer: {@answer}</p> --%>
    <div class="grid grid-cols-5 gap-x-3 gap-y-1 max-w-md mx-auto mt-4">
      <%= for guess <- 1..10 do %>
        <.simple_form for={@form} phx-submit="answer" class="text-center">
          <.input type="hidden" field={@form[:guess]} value={guess} />
          <.button type="submit" class="w-full">
            {guess}
          </.button>
        </.simple_form>
      <% end %>
    </div>

    <body>
      <div>
        This is a simple Guessing Game. The site will pick a random number between 1 and 10 and
        you will have 5 guesses to get the correct answer. At any point you can exit and save your high score,
        you will not be able to come back to your streak. Your score will also go to 0 if you run out of guesses.<br /><br />
        <br />#TODO: <br />Fix the CSS
        <br />Add in a param to keep track of a current session high score
        <br />Add in a betting button to wager your score for more points
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
    answer = Enum.random(1..10)

    {:ok,
     assign(
       socket,
       answer: answer,
       score: 0,
       attempt: 1,
       form: to_form(%{"guess" => ""})
     )}
  end

  def handle_event("answer", params, socket) do
    cond do
      to_string(socket.assigns.answer) == params["guess"] ->
        {:noreply,
         assign(
           socket
           |> put_flash(:info, "Correct!"),
           answer: Enum.random(1..10),
           score: socket.assigns.score + 1,
           attempt: 0,
           form: to_form(%{"guess" => ""})
         )}

      socket.assigns.attempt < 5 ->
        form_data = %{"guess" => ""}
        new_form = to_form(form_data)

        {:noreply,
         assign(
           socket
           |> put_flash(:info, "Incorrect."),
           attempt: socket.assigns.attempt + 1,
           form: new_form
         )}

      socket.assigns.attempt >= 5 ->
        {:noreply,
         socket
         |> put_flash(:info, "Out of Guesses.")
         |> assign(
           attempt: 1,
           score: 0,
           answer: Enum.random(1..10),
           form: to_form(%{"guess" => ""})
         )}
    end
  end

  @doc """
  These functions below are used to set the scores for a player. You will have to have unique scores
  for each game and player.
  """
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
