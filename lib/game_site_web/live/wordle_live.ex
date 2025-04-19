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
    24 => "bg-gray-100",
    25 => "bg-gray-100",
    26 => "bg-gray-100",
    27 => "bg-gray-100",
    28 => "bg-gray-100",
    29 => "bg-gray-100"
  }

  @starting_entries %{
    first: %{l1: "1", l2: "1", l3: "1", l4: "1", l5: "1"},
    second: %{l1: "2", l2: "2", l3: "2", l4: "2", l5: "2"},
    third: %{l1: "3", l2: "3", l3: "3", l4: "3", l5: "3"},
    fourth: %{l1: "4", l2: "4", l3: "4", l4: "4", l5: "4"},
    fifth: %{l1: "5", l2: "5", l3: "5", l4: "5", l5: "5"},
    sixth: %{l1: "6", l2: "6", l3: "6", l4: "6", l5: "6"}
  }

  def render(assigns) do
    ~H"""
    <p>Highest Score/Streak: {@highest_score}/{@highest_streak}</p>
    <p>Score/Streak: {@score}/{@streak}</p>
    <%= if @reset == true do %>
      <p>Word: {@word}</p>
    <% end %>
    <% round_order = [:first, :second, :third, :fourth, :fifth, :sixth] %>

    <% labels =
      for round <- round_order,
          letter <- 1..5 do
        Map.get(@entry[round], :"l#{letter}")
      end %>

    <div class="grid grid-cols-5 gap-2 sm:gap-4">
      <%= for {label, index} <- Enum.with_index(labels) do %>
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
          <.input type="text" field={@form[:guess]} label="Guess" key={@form} />
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
        (number of guesses) the higher score you will receive. <br />
        <br />
        <br />#todo: <br />Add a keyboard with colors
        <br />Make sure that the cell for the answer is cleared every time.
        <br />Make sure that once a letter is used it can no longer show up as yellow.
      </div>
    </body>
    <.simple_form id="exit-form" for={@form} phx-submit="exit">
      <.input type="hidden" field={@form[:user_id]} value={@current_user.id} />
      <.input type="hidden" field={@form[:game_id]} value={4} />
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
      |> assign(score: 0)
      |> assign(streak: 0)
      |> assign(highest_score: 0)
      |> assign(highest_streak: 0)
      |> assign(round: 0)
      |> assign(reset: false)
      |> assign(form: to_form(%{"guess" => ""}))
      |> assign(word: Words.get_word())
      |> assign(entry: @starting_entries)
      |> assign(state: @starting_state)

    {:ok, socket}
  end

  def handle_event("guess", params, socket) do
    if Words.is_word?(params["guess"]) do
      colors = feedback(socket.assigns.word, params["guess"])
      state = set_colors(colors, socket.assigns.round, socket.assigns.state)
      entires = entries(socket.assigns.entry, params["guess"], socket.assigns.round)
      score = (6 - socket.assigns.round) * 10 + socket.assigns.score
      IO.inspect(socket.assigns.word)

      cond do
        correct?(colors) and
            socket.assigns.round <= 5 ->
          socket =
            socket
            |> assign(score: score)
            |> assign(highest_score: max(score, socket.assigns.highest_score))
            |> assign(streak: socket.assigns.streak + 1)
            |> assign(highest_streak: max(socket.assigns.highest_streak, socket.assigns.streak + 1))
            |> assign(round: 0)
            |> assign(reset: true)
            |> assign(form: to_form(%{"guess" => ""}))
            |> assign(entry: entires)
            |> assign(state: state)

          {:noreply, socket}

        socket.assigns.round < 5 ->
          socket =
            socket
            |> assign(round: socket.assigns.round + 1)
            |> assign(reset: false)
            |> assign(form: to_form(%{"guess" => ""}))
            |> assign(entry: entires)
            |> assign(state: state)

          {:noreply, socket}

        socket.assigns.round == 5 ->
          socket =
            socket
            |> assign(score: 0)
            |> assign(round: 0)
            |> assign(streak: 0)
            |> assign(reset: true)
            |> assign(form: to_form(%{"guess" => ""}))
            |> assign(entry: entires)
            |> assign(state: state)

          {:noreply, socket}
      end
    else
      socket =
        socket
        |> assign(form: to_form(%{"guess" => ""}, errors: [guess: {"Not a Valid Word", []}]))

      {:noreply, socket}
    end
  end

  def handle_event("reset", _params, socket) do
    socket =
      socket
      |> assign(state: @starting_state)
      |> assign(round: 0)
      |> assign(reset: false)
      |> assign(form: to_form(%{guess: ""}))
      |> assign(word: Words.get_word())
      |> assign(entry: @starting_entries)

    {:noreply, socket}
  end

  def handle_event("exit", params, socket) do
    save_score(socket, :new, params)
  end

  defp entries(entries, word, round) do
    word_letters = String.split(word, "", trim: true)

    line_keys = [:first, :second, :third, :fourth, :fifth, :sixth]
    line_key = Enum.at(line_keys, round)

    updated_line =
      Enum.with_index(word_letters)
      |> Enum.reduce(entries[line_key], fn {letter, i}, acc ->
        put_in(acc[:"l#{i + 1}"], letter)
      end)

    put_in(entries[line_key], updated_line)
  end

  defp feedback(word, guess) do
    index_word =
      word
      |> String.split("", trim: true)
      |> Enum.with_index()

    index_guess =
      guess
      |> String.downcase()
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
    offset = round * 5

    Enum.reduce(0..4, state, fn i, acc ->
      {color, _} = List.pop_at(colors, i, :gray)
      put_in(acc[offset + i], color)
    end)
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
