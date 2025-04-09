defmodule GameSiteWeb.WordleLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores
  alias GameSiteWeb.Words

  @starting_state %{
    0 => "bg-gray-100",
    1 => "bg-gray-100",
    2 => "bg-gray-100",
    3 => "bg-gray-100",
    4 => "bg-gray-100",
    5 => "bg-gray-100",
    6 => "bg-gray-100",
    7 => "bg-gray-100",
    8 => "bg-gray-100",
    9 => "bg-gray-100",
    10 => "bg-gray-100",
    11 => "bg-gray-100",
    12 => "bg-gray-100",
    13 => "bg-gray-100",
    14 => "bg-gray-100",
    15 => "bg-gray-100",
    16 => "bg-gray-100",
    17 => "bg-gray-100",
    18 => "bg-gray-100",
    19 => "bg-gray-100",
    20 => "bg-gray-100",
    21 => "bg-gray-100",
    22 => "bg-gray-100",
    23 => "bg-gray-100",
    24 => "bg-gray-100"
  }

  def render(assigns) do
    ~H"""
    <p>Score: {@score}</p>
    <p>Word: {@word}</p>
    <div class="grid grid-cols-5 gap-4">
      <%= for {label, index} <- Enum.with_index([
    "01", "01", "01", "01", "15",
    "02", "02", "02", "02", "02",
    "03", "03", "03", "03", "03",
    "04", "04", "04", "04", "04",
    "51", "05", "05", "05", "05"
    ]) do %>
        <div class={"p-4 text-center rounded " <> Map.get(@state, index)}>
          {label}
        </div>
      <% end %>
    </div>
    <%= if @reset == true do %>
      <div class="reset-input">
        <.simple_form id="input-form" for={@form} phx-submit="reset">
          <:actions>
            <.button class="px-6 py-2 text-lg">Reset</.button>
          </:actions>
        </.simple_form>
      </div>
    <% end %>
    <%= if @reset == false do %>
      <div class="user-input">
        <.simple_form id="input-form" for={@form} phx-submit="guess">
          <.input type="text" field={@form[:guess]} label="Guess" />
          <:actions>
            <.button class="px-6 py-2 text-lg">Submit</.button>
          </:actions>
        </.simple_form>
      </div>
    <% end %>
    <body>
      <div>
        Wordle game. For this game you will be asked to find a 5 letter word, once you have submitted a
        5 letter word, you will be given feedback on how close you are to the word. A green box means that
        you have the right letter and position. A yellow box means that you have a letter in the word but
        it's not in the right place. A grey box means that the letter isn't even in the word. The faster
        (number of guesses) the higher score you will receive.
        <br />Please enjoy below is a list of things I want to add. <br />#todo:
        <br />add a wager button (for more points)
      </div>
    </body>
    <.simple_form id="exit-form" for={@form} phx-submit="exit">
      <.input type="hidden" field={@form[:user_id]} value={@current_user.id} />
      <.input type="hidden" field={@form[:game_id]} value={4} />
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
       state: @starting_state,
       score: 0,
       form: to_form(%{}),
       word: Words.get_word(),
       round: 0,
       reset: false
     )}
  end

  def handle_event("guess", params, socket) do
    colors = feedback(socket.assigns.word, params["guess"])
    state = set_colors(colors, socket.assigns.round, socket.assigns.state)

    cond do
      correct?(colors) and
          socket.assigns.round <= 4 ->
        score = (5 - socket.assigns.round) * 10

        {:noreply,
         assign(
           socket,
           round: 0,
           score: socket.assigns.score + score,
           state: state,
           reset: true
         )}

      socket.assigns.round < 4 ->
        {:noreply,
         assign(
           socket,
           round: socket.assigns.round + 1,
           state: state
         )}

      socket.assigns.round == 4 ->
        {:noreply,
         assign(
           socket,
           round: 0,
           word: Words.get_word(),
           state: state,
           reset: true
         )}
    end
  end

  def handle_event("reset", params, socket) do
    {:noreply,
     assign(
       socket,
       round: 0,
       state: @starting_state,
       word: Words.get_word(),
       reset: false,
       form: to_form(%{})
     )}
  end

  defp feedback(word, guess) do
    index_word =
      word
      |> String.split("", trim: true)
      |> Enum.with_index()

    index_guess =
      guess
      |> String.split("", trim: true)
      |> Enum.with_index()

    Enum.map(index_guess, fn {letter, index} ->
      cond do
        {letter, index} in index_word -> "bg-green-400"
        letter in String.split(word, "", trim: true) -> "bg-yellow-300"
        true -> "bg-gray-300"
      end
    end)
  end

  defp set_colors(colors, round, state) do
    case round do
      0 ->
        {color, _list} = List.pop_at(colors, 0, :gray)
        state = put_in(state[0], color)
        {color, _list} = List.pop_at(colors, 1, :gray)
        state = put_in(state[1], color)
        {color, _list} = List.pop_at(colors, 2, :gray)
        state = put_in(state[2], color)
        {color, _list} = List.pop_at(colors, 3, :gray)
        state = put_in(state[3], color)
        {color, _list} = List.pop_at(colors, 4, :gray)
        state = put_in(state[4], color)

      1 ->
        {color, _list} = List.pop_at(colors, 0, :gray)
        state = put_in(state[5], color)
        {color, _list} = List.pop_at(colors, 1, :gray)
        state = put_in(state[6], color)
        {color, _list} = List.pop_at(colors, 2, :gray)
        state = put_in(state[7], color)
        {color, _list} = List.pop_at(colors, 3, :gray)
        state = put_in(state[8], color)
        {color, _list} = List.pop_at(colors, 4, :gray)
        state = put_in(state[9], color)

      2 ->
        {color, _list} = List.pop_at(colors, 0, :gray)
        state = put_in(state[10], color)
        {color, _list} = List.pop_at(colors, 1, :gray)
        state = put_in(state[11], color)
        {color, _list} = List.pop_at(colors, 2, :gray)
        state = put_in(state[12], color)
        {color, _list} = List.pop_at(colors, 3, :gray)
        state = put_in(state[13], color)
        {color, _list} = List.pop_at(colors, 4, :gray)
        state = put_in(state[14], color)

      3 ->
        {color, _list} = List.pop_at(colors, 0, :gray)
        state = put_in(state[15], color)
        {color, _list} = List.pop_at(colors, 1, :gray)
        state = put_in(state[16], color)
        {color, _list} = List.pop_at(colors, 2, :gray)
        state = put_in(state[17], color)
        {color, _list} = List.pop_at(colors, 3, :gray)
        state = put_in(state[18], color)
        {color, _list} = List.pop_at(colors, 4, :gray)
        state = put_in(state[19], color)

      4 ->
        {color, _list} = List.pop_at(colors, 0, :gray)
        state = put_in(state[20], color)
        {color, _list} = List.pop_at(colors, 1, :gray)
        state = put_in(state[21], color)
        {color, _list} = List.pop_at(colors, 2, :gray)
        state = put_in(state[22], color)
        {color, _list} = List.pop_at(colors, 3, :gray)
        state = put_in(state[23], color)
        {color, _list} = List.pop_at(colors, 4, :gray)
        state = put_in(state[24], color)
    end
  end

  def handle_event("exit", params, socket) do
    save_score(socket, :new, params)
  end

  defp correct?(colors) do
    if colors == ["bg-green-400", "bg-green-400", "bg-green-400", "bg-green-400", "bg-green-400"] do
      true
    else
      false
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
