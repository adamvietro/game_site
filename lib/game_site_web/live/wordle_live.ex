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
    first: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."},
    second: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."},
    third: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."},
    fourth: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."},
    fifth: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."},
    sixth: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."}
  }

  @starting_keyboard %{
    q: "bg-gray-100",
    w: "bg-gray-100",
    e: "bg-gray-100",
    r: "bg-gray-100",
    t: "bg-gray-100",
    y: "bg-gray-100",
    u: "bg-gray-100",
    i: "bg-gray-100",
    o: "bg-gray-100",
    p: "bg-gray-100",
    a: "bg-gray-100",
    s: "bg-gray-100",
    d: "bg-gray-100",
    f: "bg-gray-100",
    g: "bg-gray-100",
    h: "bg-gray-100",
    j: "bg-gray-100",
    k: "bg-gray-100",
    l: "bg-gray-100",
    z: "bg-gray-100",
    x: "bg-gray-100",
    c: "bg-gray-100",
    v: "bg-gray-100",
    b: "bg-gray-100",
    n: "bg-gray-100",
    m: "bg-gray-100"
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
          <.input type="text" value={@guess_string} label="Guess" disabled name="no-input" />
          <.input type="hidden" field={@form[:guess]} value={@guess_string} />

          <:actions>
            <.button class="px-6 py-2 text-lg">Submit</.button>
          </:actions>
        </.simple_form>
      </div>
    <% end %>

    <div><br /></div>

    <div class="space-y-1 sm:space-y-2 text-sm">
      <div class="grid grid-cols-10 gap-1 sm:gap-2">
        <%= for key <- [:q, :w, :e, :r, :t, :y, :u, :i, :o, :p] do %>
          <div
            phx-click="add_letter"
            phx-value-letter={Atom.to_string(key)}
            class={"cursor-pointer w-8 sm:w-10 p-1 sm:p-2 text-center rounded " <> @keyboard[key]}
          >
            {Atom.to_string(key) |> String.upcase()}
          </div>
        <% end %>
      </div>

      <div class="grid grid-cols-9 gap-1 sm:gap-2">
        <%= for key <- [:a, :s, :d, :f, :g, :h, :j, :k, :l] do %>
          <div
            phx-click="add_letter"
            phx-value-letter={Atom.to_string(key)}
            class={"cursor-pointer w-8 sm:w-10 p-1 sm:p-2 text-center rounded " <> @keyboard[key]}
          >
            {Atom.to_string(key) |> String.upcase()}
          </div>
        <% end %>
      </div>

      <div class="grid grid-cols-7 gap-1 sm:gap-2">
        <%= for key <- [:z, :x, :c, :v, :b, :n, :m] do %>
          <div
            phx-click="add_letter"
            phx-value-letter={Atom.to_string(key)}
            class={"cursor-pointer w-8 sm:w-10 p-1 sm:p-2 text-center rounded " <> @keyboard[key]}
          >
            {Atom.to_string(key) |> String.upcase()}
          </div>
        <% end %>
      </div>
      <div class="mt-2 grid grid-cols-3 gap-1 sm:gap-2">
        <div
          phx-click="delete_letter"
          class="col-span-1 p-2 text-center rounded bg-red-200 cursor-pointer"
        >
          Delete
        </div>
      </div>
    </div>

    <body>
      <div>
        <br />
        Wordle game. For this game you will be asked to find a 5 letter word, once you have submitted a
        5 letter word, you will be given feedback on how close you are to the word. A green box means that
        you have the right letter and position. A yellow box means that you have a letter in the word but
        it's not in the right place. A grey box means that the letter isn't even in the word. The faster
        (number of guesses) the higher score you will receive. You can only use the on screen keyboard to
        enter a word.<br />
        <br />#TODO: <br />Make sure that once a letter is used it can no longer show up as yellow.
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
      |> assign(guess_string: "")
      |> assign(form: to_form(%{"guess" => ""}))
      |> assign(word: word = Words.get_word())
      |> assign(entry: @starting_entries)
      |> assign(state: @starting_state)
      |> assign(keyboard: @starting_keyboard)

    IO.inspect(word)

    {:ok, socket}
  end

  def handle_event("delete_letter", _, socket) do
    if socket.assigns.guess_string == "" do
      {:noreply, socket}
    else
      updated = socket.assigns.guess_string |> String.slice(0..-2//1)
      {:noreply, assign(socket, guess_string: updated)}
    end
  end

  def handle_event("add_letter", %{"letter" => letter}, socket) do
    current = socket.assigns.guess_string || ""

    if String.length(current) < 5 do
      {:noreply, assign(socket, guess_string: current <> letter)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("guess", %{"guess" => guess} = _params, socket) do
    IO.inspect(%{answer: socket.assigns.word, guess: guess}, label: "Words")

    if Words.is_word?(String.downcase(guess)) do
      letters_colors =
        feedback(socket.assigns.word, guess)

      # |> IO.inspect(label: "Letters Colors")

      state =
        set_colors(letters_colors, socket.assigns.round, socket.assigns.state)

      # |> IO.inspect(label: "State")

      entires =
        entries(socket.assigns.entry, guess, socket.assigns.round)

      # |> IO.inspect(label: "Entires")

      keyboard =
        set_keyboard(letters_colors, socket.assigns.keyboard)

      # |> IO.inspect(label: "keyboard")

      score = (6 - socket.assigns.round) * 10 + socket.assigns.score

      cond do
        guess == socket.assigns.word and
            socket.assigns.round <= 5 ->
          socket =
            socket
            |> assign(score: score)
            |> assign(highest_score: max(score, socket.assigns.highest_score))
            |> assign(streak: socket.assigns.streak + 1)
            |> assign(
              highest_streak: max(socket.assigns.highest_streak, socket.assigns.streak + 1)
            )
            |> assign(round: 0)
            |> assign(reset: true)
            |> assign(guess_string: "")
            |> assign(form: to_form(%{"guess" => ""}))
            |> assign(entry: entires)
            |> assign(state: state)
            |> assign(keyboard: keyboard)

          {:noreply, socket}

        socket.assigns.round < 5 ->
          socket =
            socket
            |> assign(round: socket.assigns.round + 1)
            |> assign(reset: false)
            |> assign(guess_string: "")
            |> assign(form: to_form(%{"guess" => ""}))
            |> assign(entry: entires)
            |> assign(state: state)
            |> assign(keyboard: keyboard)

          {:noreply, socket}

        socket.assigns.round == 5 ->
          socket =
            socket
            |> assign(score: 0)
            |> assign(round: 0)
            |> assign(streak: 0)
            |> assign(reset: true)
            |> assign(guess_string: "")
            |> assign(form: to_form(%{"guess" => ""}))
            |> assign(entry: entires)
            |> assign(state: state)
            |> assign(keyboard: keyboard)

          {:noreply, socket}
      end
    else
      socket =
        socket
        |> assign(guess_string: "")
        |> assign(form: to_form(%{"guess" => ""}, errors: [guess: {"Not a Valid Word", []}]))

      {:noreply, socket}
    end
  end

  def handle_event("guess", _, socket) do
    # maybe log and ignore bad submissions, or show error
    {:noreply, put_flash(socket, :error, "Invalid guess submission")}
  end

  def handle_event("reset", _params, socket) do
    socket =
      socket
      |> assign(state: @starting_state)
      |> assign(round: 0)
      |> assign(reset: false)
      |> assign(guess_string: "")
      |> assign(form: to_form(%{"guess" => ""}))
      |> assign(word: word = Words.get_word())
      |> assign(entry: @starting_entries)
      |> assign(keyboard: @starting_keyboard)

    IO.inspect(word)
    {:noreply, socket}
  end

  def handle_event("exit", params, socket) do
    save_score(socket, :new, params)
  end

  defp letter_count(word) do
    word_list = String.split(word, "", trim: true)

    Enum.reduce(word_list, %{}, fn letter, acc ->
      Map.update(acc, letter, 1, fn count -> count + 1 end)
    end)
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

    letter_count =
      letter_count(word)
      |> IO.inspect(label: "Letter Count")

    {result, _final_letter_count} =
      Enum.map_reduce(index_guess, letter_count, fn {letter, index}, letter_count ->
        cond do
          {letter, index} in index_word ->
            letter_count = Map.update!(letter_count, letter, fn count -> count - 1 end)
            IO.inspect(letter_count, label: "green")
            {[letter, "bg-green-400"], letter_count}

          letter in String.split(word, "", trim: true) and letter_count[letter] > 0 ->
            letter_count = Map.update!(letter_count, letter, fn count -> count - 1 end)
            IO.inspect(letter_count, label: "yellow")
            {[letter, "bg-yellow-300"], letter_count}

          true ->
            {[letter, "bg-gray-300"], letter_count}
        end
      end)
      result
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

  defp set_colors(colors, round, state) do
    offset = round * 5

    Enum.reduce(0..4, state, fn i, acc ->
      {[_letter, color], _} = List.pop_at(colors, i, :gray)
      put_in(acc[offset + i], color)
    end)
  end

  defp set_keyboard(letters_colors, keyboard) do
    Enum.reduce(letters_colors, keyboard, fn [letter, color], acc ->
      Map.replace(acc, String.to_atom(letter), color)
    end)
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
