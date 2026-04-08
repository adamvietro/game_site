defmodule GameSiteWeb.Live.WordleLive.GameLogic do
  alias GameSite.Wordle.Words
  alias GameSiteWeb.Live.WordleLive.Defaults

  defstruct score: 0,
            current_streak: 0,
            highest_score: 0,
            highest_streak: 0,
            round: 0,
            reset: false,
            word: "",
            guess_string: "",
            win?: false,
            errors: nil,
            entries: Defaults.starting_entries(),
            board_state: Defaults.starting_board(),
            keyboard_state: Defaults.starting_keyboard()

  def new(attr \\ %{}) do
    struct(__MODULE__, Map.merge(Map.from_struct(%__MODULE__{}), attr))
  end

  def new(attr, guess) do
    struct(
      __MODULE__,
      Map.merge(Map.from_struct(%__MODULE__{}), attr) |> Map.put(:guess_string, guess)
    )
  end

  def to_map(%__MODULE__{} = game_state) do
    Map.from_struct(game_state)
  end

  def get_starting_entries, do: Defaults.starting_entries()
  def get_starting_board, do: Defaults.starting_board()
  def get_starting_keyboard, do: Defaults.starting_keyboard()

  def get_new_word, do: Words.get_word()

  def determine_round(%__MODULE__{} = game_state) do
    game_state
    |> determine_is_word()
    |> determine_feedback()
    |> determine_win()
    |> determine_final_state()
  end

  defp determine_is_word(%__MODULE__{guess_string: guess} = game_state) do
    if Words.is_word?(String.downcase(guess)) do
      %{game_state | errors: nil}
    else
      %{game_state | errors: "Not a valid word"}
    end
  end

  defp determine_feedback(%__MODULE__{errors: "Not a valid word"} = game_state), do: game_state

  defp determine_feedback(
         %__MODULE__{
           guess_string: guess,
           entries: entries,
           round: round,
           word: word,
           board_state: board_state,
           keyboard_state: keyboard_state
         } =
           game_state
       ) do
    letters_colors = letter_feedback(word, guess)

    entries = set_entries(entries, guess, round)
    board_state = set_board_colors(letters_colors, round, board_state)

    keyboard_state = set_keyboard_colors(letters_colors, keyboard_state)

    %{
      game_state
      | board_state: board_state,
        keyboard_state: keyboard_state,
        entries: entries
    }
  end

  defp letter_feedback(word, guess) do
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

    {green_results, letter_count_after_greens} =
      Enum.map_reduce(index_guess, letter_count, fn {letter, index}, letter_count ->
        cond do
          {letter, index} in index_word ->
            letter_count = Map.update!(letter_count, letter, fn count -> count - 1 end)
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
            {[letter, "bg-yellow-300"], letter_count}
          else
            {[letter, "bg-gray-300"], letter_count}
          end

        [letter, color], letter_count ->
          {[letter, color], letter_count}
      end)

    result
  end

  defp letter_count(word) do
    word_list = String.split(word, "", trim: true)

    Enum.reduce(word_list, %{}, fn letter, acc ->
      Map.update(acc, letter, 1, fn count -> count + 1 end)
    end)
  end

  defp set_board_colors(colors, round, state) do
    offset = round * 5

    Enum.reduce(0..4, state, fn i, acc ->
      {[_letter, color], _} = List.pop_at(colors, i, :gray)
      put_in(acc[offset + i], color)
    end)
  end

  defp set_keyboard_colors(letters_colors, keyboard) do
    Enum.reduce(letters_colors, keyboard, fn [letter, new_color], acc ->
      key = String.to_atom(letter)
      current_color = Map.get(acc, key)

      if color_priority(new_color) > color_priority(current_color) do
        Map.put(acc, key, new_color)
      else
        acc
      end
    end)
  end

  defp set_entries(entries, word, round) do
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

  defp determine_win(%__MODULE__{errors: "Not a valid word"} = game_state), do: game_state

  defp determine_win(%__MODULE__{guess_string: guess, word: word} = game_state) do
    if guess == word do
      %{game_state | win?: true}
    else
      game_state
    end
  end

  defp determine_final_state(%__MODULE__{errors: "Not a valid word"} = game_state), do: game_state

  defp determine_final_state(%__MODULE__{win?: false, round: round} = game_state) when round < 5,
    do: %{game_state | round: round + 1, guess_string: ""}

  defp determine_final_state(%__MODULE__{win?: false, round: round} = game_state)
       when round == 5,
       do: %{game_state | reset: true, current_streak: 0, score: 0, round: 0, guess_string: ""}

  defp determine_final_state(
         %__MODULE__{
           win?: true,
           round: round,
           score: score,
           highest_streak: highest_streak,
           current_streak: current_streak,
           highest_score: highest_score
         } = game_state
       ) do
    score = (6 - round) * 10 + score
    current_streak = current_streak + 1
    highest_streak = max(current_streak, highest_streak)

    %{
      game_state
      | score: score,
        highest_score: max(highest_score, score),
        current_streak: current_streak,
        highest_streak: highest_streak,
        reset: true,
        win?: false,
        guess_string: ""
    }
  end

  defp color_priority("bg-gray-100"), do: 0
  defp color_priority("bg-gray-300"), do: 1
  defp color_priority("bg-yellow-300"), do: 2
  defp color_priority("bg-green-400"), do: 3
  defp color_priority(_), do: 0
end
