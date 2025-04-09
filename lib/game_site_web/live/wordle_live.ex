defmodule GameSiteWeb.WordleLive do
  use GameSiteWeb, :live_view

  alias GameSite.Scores
  alias GameSiteWeb.Words

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
    <div class="user-input">
      <.simple_form id="input-form" for={@form} phx-submit="guess">
        <.input type="text" field={@form[:guess]} label="Guess" />
        <:actions>
          <.button class="px-6 py-2 text-lg">Submit</.button>
        </:actions>
      </.simple_form>
    </div>
    <body>
      <div>
        Wordle game. For this game you will be asked to find a 5 letter word, once you have submitted a
        5 letter word, you will be given feedback on how close you are to the word. A green box means that
        you have the right letter and position. A yellow box means that you have a letter in the word but
        it's not in the right place. A grey box means that the letter isn't even in the word. The faster
        (number of guesses) the higher score you will receive.
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
       state: %{
         0 => "bg-gray-200",
         1 => "bg-gray-200",
         2 => "bg-gray-200",
         3 => "bg-gray-200",
         4 => "bg-gray-200",
         5 => "bg-gray-200",
         6 => "bg-gray-200",
         7 => "bg-gray-200",
         8 => "bg-gray-200",
         9 => "bg-gray-200",
         10 => "bg-gray-200",
         11 => "bg-gray-200",
         12 => "bg-gray-200",
         13 => "bg-gray-200",
         14 => "bg-gray-200",
         15 => "bg-gray-200",
         16 => "bg-gray-200",
         17 => "bg-gray-200",
         18 => "bg-gray-200",
         19 => "bg-gray-200",
         20 => "bg-gray-200",
         21 => "bg-gray-200",
         22 => "bg-gray-200",
         23 => "bg-gray-200",
         24 => "bg-gray-200"
       },
       score: 0,
       session_high_score: 0,
       form: to_form(%{}),
       word: Words.get_word(),
       round: 0
     )}
  end

  def handle_event("guess", params, socket) do
    colors = feedback(socket.assigns.word, params["guess"])
    socket = set_colors(colors, socket.assigns.round, socket)

    {:noreply, assign(socket, round: socket.assigns.round + 1)}

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
        {letter, index} in index_word -> "bg-green-200"
        letter in String.split(word, "", trim: true) -> "bg-yellow-200"
        true -> "bg-gray-200"
      end
    end)
  end

  defp set_colors(colors, round, state) do
    IO.inspect(state)
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
