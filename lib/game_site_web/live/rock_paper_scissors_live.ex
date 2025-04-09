defmodule GameSiteWeb.RockPaperScissorsLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores

  def render(assigns) do
    ~H"""
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
        ten points draws will not effect your points. You will simply click a button and roll the dice, or scissors?
        At any point you can exit this page it will submit your current score (know when to hold'en and fold'em). You
        can't come back to a current streak once you exit or refresh the page.
        <br />Please enjoy below is a list of things I want to add. <br />#todo:
        <br />add a wager button (for more points) <br />add a param for highest score for the session
        <br />keep only the highest 5 scores for each player <br />change it to any size of questions
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
       session_high_score: 0,
       form: to_form(%{}),
       outcome: ""
     )}
  end

  def handle_event("exit", params, socket) do
    save_score(socket, :new, params)
  end

  def handle_event("rock", _params, socket) do
    set_assign("rock", socket)
  end

  def handle_event("paper", _params, socket) do
    set_assign("rock", socket)
  end

  def handle_event("scissors", _params, socket) do
    set_assign("rock", socket)
  end

  defp computer_choose() do
    Enum.random(["rock", "paper", "scissor"])
  end

  defp beats?(player, computer),
    do: {player, computer} in [{"rock", "scissor"}, {"scissor", "paper"}, {"paper", "rock"}]

  defp set_assign(player, socket) do
    cond do
      socket.assigns.computer == player ->
        {:noreply,
         assign(
           socket,
           computer: computer_choose(),
           score: socket.assigns.score,
           session_high_score: 0,
           form: to_form(%{}),
           outcome: "You Tie!"
         )}

      beats?("rock", socket.assigns.computer) ->
        {:noreply,
         assign(
           socket,
           computer: computer_choose(),
           score: socket.assigns.score + 10,
           session_high_score: 0,
           form: to_form(%{}),
           outcome: "You Win!"
         )}

      true ->
        {:noreply,
         assign(
           socket,
           computer: computer_choose(),
           score: socket.assigns.score - 10,
           session_high_score: 0,
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
