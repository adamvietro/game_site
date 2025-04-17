defmodule GameSiteWeb.RockPaperScissorsLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores
  alias Ecto.Changeset
  alias GameSiteWeb.HelperFunctions, as: Helper

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
        <.simple_form id="rock-form" for={@form} phx-submit="rock">
          <.input type="hidden" field={@form[:player_choice]} />
          <:actions>
            <.button class="px-6 py-2 text-lg">Rock</.button>
          </:actions>
        </.simple_form>

        <.simple_form id="paper-form" for={@form} phx-submit="paper">
          <.input type="hidden" field={@form[:player_choice]} />
          <:actions>
            <.button class="px-6 py-2 text-lg">Paper</.button>
          </:actions>
        </.simple_form>

        <.simple_form id="scissors-form" for={@form} phx-submit="scissors">
          <.input type="hidden" field={@form[:player_choice]} />
          <:actions>
            <.button class="px-6 py-2 text-lg">Scissors</.button>
          </:actions>
        </.simple_form>
      </div>
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
       score: 0,
       highest_score: 0,
       form: to_form(%{}),
       outcome: "",
       wager: 1
     )}
  end

  def handle_event("exit", params, socket) do
    save_score(socket, :new, params)
  end

  def handle_event("rock", params, socket) do
    set_assign(socket, params)
  end

  def handle_event("paper", params, socket) do
    set_assign(socket, params)
  end

  def handle_event("scissors", params, socket) do
    set_assign(socket, params)
  end

  defp set_event_info(socket, params) do
    parsed_wager =
      Helper.add_subtract_wager(params.wager, params.player.choice, socket.assigns.computer)

    %{
      computer: socket.assigns.computer,
      player: params.player.choice,
      correct: params.player.choice == socket.assigns.computer,
      current_score: socket.assigns.score + parsed_wager,
      wager: params.wager,
      parsed_wager: parsed_wager,
      highest_score: max(socket.assigns.score + parsed_wager, socket.assigns.highest_score),
      form: to_form(%{})
    }
  end

  defp computer_choose() do
    Enum.random(["rock", "paper", "scissor"])
  end

  defp beats?(player, computer),
    do: {player, computer} in [{"rock", "scissor"}, {"scissor", "paper"}, {"paper", "rock"}]

  defp set_assign(socket, params) do
    event_info = set_event_info(socket, params)
    |> IO.inspect(label: "Event info")

    cond do
      socket.assigns.computer == params.player_choice ->
        {:noreply,
         assign(
           socket,
           computer: computer_choose(),
           score: socket.assigns.score,
           highest_score: 0,
           form: to_form(%{}),
           outcome: "You Tie!"
         )}

      beats?(params.player_choice, socket.assigns.computer) ->
        {:noreply,
         assign(
           socket,
           computer: computer_choose(),
           score: socket.assigns.score + 10,
           highest_score: 0,
           form: to_form(%{}),
           outcome: "You Win!"
         )}

      true ->
        {:noreply,
         assign(
           socket,
           computer: computer_choose(),
           score: socket.assigns.score - 10,
           highest_score: 0,
           form: to_form(%{}),
           outcome: "You Lose!"
         )}
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
