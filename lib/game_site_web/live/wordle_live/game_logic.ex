defmodule GameSiteWeb.Live.WordleLive.GameLogic do
  alias GameSiteWeb.Words
  alias GameSiteWeb.Live.WordleLive.Defaults

  defstruct score: 0,
            streak: 0,
            highest_score: 0,
            highest_streak: 0,
            round: 0,
            reset: false,
            guess_string: "",
            form: %{"guess" => ""},
            entry: Defaults.starting_entries(),
            board_state: Defaults.starting_state(),
            keyboard: Defaults.starting_keyboard()
end
