defmodule GameSiteWeb.RockPaperScissorsLive do
  use GameSiteWeb, :live_view

  import GameSiteWeb.LoginHelpers
  alias GameSite.Scores

  def render(assigns) do
    ~H"""
    <%!-- <div class="max-w-2xl mx-auto p-6 space-y-6 bg-white shadow-md rounded-lg"> --%>
    <section class="bg-gray-50 rounded p-4 shadow space-y-4">
      <div class="text-left mx-auto text-left">
        <h2 class="text-xl font-semibold mb-2">How to Play</h2>
        <p>
          Rock Paper Scissors — simple but fun! Each win earns you the amount you wager
          each loss deducts it. Choose your move and test your luck.
        </p>
        <ul class="list-disc list-inside mt-2 space-y-1 text-gray-700">
          <li>Rock beats Scissors</li>
          <li>Scissors beats Paper</li>
          <li>Paper beats Rock</li>
          <li>If both choose the same move, it's a tie</li>
          <li>Game resets if your score hits 0, but your high score is saved</li>
        </ul>
      </div>

      <div class="bg-gray-50 rounded p-4 shadow max-w-xl mx-auto flex justify-around items-center font-semibold text-gray-800">
        <div class="text-center">
          <div class="text-sm text-gray-500">Highest Score</div>
          <div class="text-lg">{@highest_score}</div>
        </div>
        <div class="text-center">
          <div class="text-sm text-gray-500">Score</div>
          <div class="text-lg">{@score}</div>
        </div>
        <%= if @outcome != "" do %>
          <div class="text-center">
            <div class="text-sm text-gray-500">Outcome</div>
            <div class="text-md text-blue-600 font-medium">{@outcome}</div>
          </div>
        <% end %>
      </div>
    </section>

    <.simple_form for={@form} phx-submit="answer" class="text-center space-y-6 max-w-xs mx-auto">
      <!-- Wager input -->
      <div>
        <label for="wager_input" class="block text-sm font-medium text-gray-700 mb-1">
          Wager
        </label>
        <input
          type="number"
          id="wager_input"
          name="wager"
          min="1"
          value={@wager}
          max={@score}
          step="1"
          class="w-full rounded-md border-gray-300 shadow-sm focus:ring-blue-500 focus:border-blue-500"
        />
      </div>

    <!-- Hidden player_choice input -->
      <input type="hidden" name="player_choice" id="player_choice" />

    <!-- Choice buttons -->
      <div class="flex justify-center gap-6">
        <%= for choice <- ["rock", "paper", "scissors"] do %>
          <button
            type="submit"
            class="w-24 bg-gray-200 hover:bg-gray-300 shadow rounded"
            phx-click={JS.exec("document.getElementById('player_choice').value = '#{choice}'")}
          >
            {String.capitalize(choice)}
          </button>
        <% end %>
      </div>
    </.simple_form>

    <div class="bg-gray-50 p-4 rounded shadow text-sm text-gray-700">
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
      <.simple_form id="exit-form" for={@form} phx-submit="exit" class="text-center">
        <.input type="hidden" field={@form[:user_id]} value={@current_user.id} />
        <.input type="hidden" field={@form[:game_id]} value={3} />
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
    socket =
      socket
      |> assign(computer: computer_choose())
      |> assign(score: 10)
      |> assign(highest_score: 0)
      |> assign(wager: 1)
      |> assign(form: to_form(%{"wager" => 1}))
      |> assign(outcome: "")

    {:ok, socket}
  end

  def handle_event("exit", params, socket) do
    save_score(socket, :new, params)
  end

  def handle_event("answer", params, socket) do
    set_assign(socket, params)
  end

  defp set_event_info(socket, %{"wager" => wager, "player_choice" => player}) do
    parsed_wager = parsed_wager(wager, player, socket.assigns.computer)

    %{
      player: player,
      computer: socket.assigns.computer,
      current_score: socket.assigns.score + parsed_wager,
      score: socket.assigns.score,
      wager: if(wager == "", do: 1, else: String.to_integer(wager)),
      highest_score: max(socket.assigns.score + parsed_wager, socket.assigns.highest_score),
      form: to_form(%{})
    }
  end

  defp parsed_wager("", player, computer) do
    if beats?(player, computer), do: 1, else: -1
  end

  defp parsed_wager(wager, player, computer) do
    if beats?(player, computer), do: String.to_integer(wager), else: -1 * String.to_integer(wager)
  end

  defp computer_choose() do
    Enum.random(["rock", "paper", "scissor"])
  end

  defp beats?(player, computer),
    do: {player, computer} in [{"rock", "scissor"}, {"scissor", "paper"}, {"paper", "rock"}]

  defp set_assign(socket, params) do
    event_info =
      set_event_info(socket, params)

    # |> IO.inspect(label: "Event info")

    cond do
      event_info.current_score <= 0 ->
        # IO.inspect("Reset")

        socket =
          socket
          |> put_flash(:error, "Score at 0, resetting.")
          |> assign(computer: computer_choose())
          |> assign(score: 10)
          |> assign(wager: 1)
          |> assign(form: to_form(%{"wager" => 1}))
          |> assign(outcome: "")

        {:noreply, socket}

      event_info.computer == event_info.player ->
        # IO.inspect("Tied")

        socket =
          socket
          |> assign(computer: computer_choose())
          |> assign(wager: event_info.wager)
          |> assign(form: to_form(%{"wager" => event_info.wager}))
          |> assign(outcome: "You Tie!")

        {:noreply, socket}

      beats?(event_info.player, event_info.computer) ->
        # IO.inspect("Won")

        socket =
          socket
          |> assign(computer: computer_choose())
          |> assign(score: event_info.current_score)
          |> assign(wager: event_info.wager)
          |> assign(highest_score: max(event_info.current_score, event_info.highest_score))
          |> assign(form: to_form(%{"wager" => event_info.wager}))
          |> assign(outcome: "You Win!")

        {:noreply, socket}

      true ->
        # IO.inspect("Lost")

        socket =
          socket
          |> assign(computer: computer_choose())
          |> assign(wager: min(event_info.wager, event_info.current_score))
          |> assign(score: event_info.current_score)
          |> assign(form: to_form(%{"wager" => event_info.wager}))
          |> assign(outcome: "You Lose!")

        {:noreply, socket}
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
