defmodule GameSiteWeb.WordleLive do
  use GameSiteWeb, :live_view

  alias GameSiteWeb.Live.WordleLive.Component, as: WordleComponent
  alias GameSiteWeb.Live.WordleLive.GameBoard
  alias GameSiteWeb.Live.WordleLive.GameLogic
  alias GameSiteWeb.Live.Component
  alias GameSite.Scores.ScoreHandler
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

  @impl true
  def render(assigns) do
    ~H"""
    <section class="bg-gray-50 rounded p-6 shadow mx-auto space-y-6">
      <WordleComponent.instructions />
      <WordleComponent.score_board
        highest_score={@highest_score}
        highest_streak={@highest_streak}
        current_score={@score}
        current_streak={@streak}
        reset={@reset}
        word={@word}
      />
    </section>
    <GameBoard.game_board board_state={@board_state} entry={@entry} />

    <WordleComponent.user_input form={@form} reset={@reset} guess_string={@guess_string} />
    <WordleComponent.keyboard keyboard={@keyboard} />

    <Component.score_submit
      form={@form}
      game_id={4}
      score={@highest_score}
      current_user={@current_user}
    />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> default_assigns()
      |> maybe_connected()

    {:ok, socket}
  end

  defp maybe_connected(socket) do
    if connected?(socket) do
      socket
      |> assign(word: Words.get_word())
    else
      socket
    end
  end

  defp default_assigns(socket) do
    socket
    |> assign(score: 0)
    |> assign(streak: 0)
    |> assign(highest_score: 0)
    |> assign(highest_streak: 0)
    |> assign(round: 0)
    |> assign(reset: false)
    |> assign(guess_string: "")
    |> assign(word: "")
    |> assign(form: to_form(%{"guess" => ""}))
    |> assign(entry: @starting_entries)
    |> assign(board_state: @starting_state)
    |> assign(keyboard: @starting_keyboard)

    ### keyboard_state: Defaults.starting_keyboard
  end

  @impl true
  def handle_event("delete_letter", _, socket) do
    if socket.assigns.guess_string == "" do
      {:noreply, socket}
    else
      updated = socket.assigns.guess_string |> String.slice(0..-2//1)
      {:noreply, assign(socket, guess_string: updated)}
    end
  end

  @impl true
  def handle_event("add_letter", %{"letter" => letter}, socket) do
    current = socket.assigns.guess_string || ""

    if String.length(current) < 5 do
      updated = String.slice(current <> letter, 0, 5)
      {:noreply, assign(socket, guess_string: updated)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("guess", %{"guess" => guess} = _params, socket) do
    IO.inspect(%{answer: socket.assigns.word, guess: guess}, label: "Guess Event")

    # guess = if guess == "", do: guess_string, else: guess?

    if Words.is_word?(String.downcase(guess)) do
      letters_colors =
        feedback(socket.assigns.word, guess)

      # |> IO.inspect(label: "Letters Colors")

      state =
        set_colors(letters_colors, socket.assigns.round, socket.assigns.board_state)

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
            |> assign(board_state: state)
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
            |> assign(board_state: state)
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
            |> assign(board_state: state)
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

  @impl true
  def handle_event("guess", _, socket) do
    # maybe log and ignore bad submissions, or show error
    {:noreply, put_flash(socket, :error, "Invalid guess submission")}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    socket =
      socket
      |> assign(board_state: @starting_state)
      |> assign(round: 0)
      |> assign(reset: false)
      |> assign(guess_string: "")
      |> assign(form: to_form(%{"guess" => ""}))
      |> assign(word: word = Words.get_word())
      |> assign(entry: @starting_entries)
      |> assign(keyboard: @starting_keyboard)

    IO.inspect(word, label: "Resetting Word")
    {:noreply, socket}
  end

  @impl true
  def handle_event("exit", params, socket) do
    ScoreHandler.save_score(socket, params)
  end

  defp letter_count(word) do
    word_list = String.split(word, "", trim: true)

    Enum.reduce(word_list, %{}, fn letter, acc ->
      Map.update(acc, letter, 1, fn count -> count + 1 end)
    end)
  end

  def feedback(word, guess) do
    # GameLogic.determine_round(game_state)
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

    # |> IO.inspect(label: "Letter Count")

    {green_results, letter_count_after_greens} =
      Enum.map_reduce(index_guess, letter_count, fn {letter, index}, letter_count ->
        cond do
          {letter, index} in index_word ->
            letter_count = Map.update!(letter_count, letter, fn count -> count - 1 end)
            # IO.inspect(letter_count, label: "green")
            {[letter, "bg-green-400"], letter_count}

          true ->
            {{letter, index}, letter_count}
        end
      end)

    {result, _letter_count} =
      Enum.map_reduce(green_results, letter_count_after_greens, fn
        {letter, _index}, letter_count ->
          if letter in String.split(word, "", trim: true) and letter_count[letter] > 0 do
            letter_count = Map.update!(letter_count, letter, fn count -> count - 1 end)
            # IO.inspect(letter_count, label: "yellow")
            {[letter, "bg-yellow-300"], letter_count}
          else
            {[letter, "bg-gray-300"], letter_count}
          end

        [letter, color], letter_count ->
          {[letter, color], letter_count}
      end)

    # IO.inspect(result)
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

  def set_colors(colors, round, state) do
    offset = round * 5

    Enum.reduce(0..4, state, fn i, acc ->
      {[_letter, color], _} = List.pop_at(colors, i, :gray)
      put_in(acc[offset + i], color)
    end)
  end

  def set_keyboard(letters_colors, keyboard) do
    Enum.reduce(letters_colors, keyboard, fn [letter, color], acc ->
      Map.replace(acc, String.to_atom(letter), color)
    end)
  end
end
