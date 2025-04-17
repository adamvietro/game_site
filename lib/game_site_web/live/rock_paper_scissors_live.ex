defmodule GameSiteWeb.RockPaperScissorsLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores
  alias Ecto.Changeset

  import Ecto.Changeset

  def render(assigns) do
    ~H"""
    <p>Highest Score: {@highest_score}</p>
    <p>Score: {@score}</p>
    <%= if @outcome != "" do %>
      <p>Outcome: {@outcome}</p>
    <% end %>
    <div class="flex justify-center mt-8">
      <div class="flex gap-6">
        <%= for choice <- ["rock", "paper", "scissors"] do %>
          <.simple_form for={@form} phx-submit="answer" class="text-center">
            <.input type="hidden" field={@form[:player_choice]} value={choice} />
            <input type="hidden" name="wager" id={"wager_hidden_#{choice}"} />

            <.button type="submit" class="w-full" phx-hook="CopyBonus">
              {choice}
            </.button>
          </.simple_form>
        <% end %>
      </div>
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
        Rock Paper Scissors. Yeah it's simple but fun. Each win will give you 10 points each loss will lose you
        ten points draws will not effect your points. You will simply click a button and roll the dice, or ?scissors?
        At any point you can exit this page it will submit your current score (know when to hold'en and fold'em). You
        can't come back to a current streak once you exit or refresh the page. <br />
        <br />
        <br />#todo: <br />Add a wager button (for more points)
        <br />Add a param for highest score for the session
      </div>
    </body>
    <.simple_form id="exit-form" for={@form} phx-submit="exit">
      <.input type="hidden" field={@form[:user_id]} value={@current_user.id} />
      <.input type="hidden" field={@form[:game_id]} value={3} />
      <.input type="hidden" field={@form[:score]} value={@score} />
      <:actions>
        <.button>Exit and Save Score</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(
       socket,
       computer: computer_choose(),
       score: 10,
       highest_score: 0,
       form: to_form(%{}),
       outcome: "",
       wager: 1
     )}
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
      wager: wager,
      highest_score: max(socket.assigns.score + parsed_wager, socket.assigns.highest_score),
      form: to_form(%{})
    }
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
      |> IO.inspect(label: "Event info")

    cond do
      event_info.computer == event_info.player ->
        IO.inspect("Tied")

        socket =
          socket
          |> assign(computer: computer_choose())
          |> assign(wager: event_info.wager)
          |> assign(form: to_form(%{"wager" => event_info.wager}))
          |> assign(outcome: "You Tie!")

        {:noreply, socket}

      beats?(event_info.player, event_info.computer) ->
        IO.inspect("Won")

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
        IO.inspect("Lost")

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
