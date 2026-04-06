defmodule GameSite.MultiPoker.Player do
  defstruct player_id: nil,
            viewer_id: nil,
            ready?: false,
            chips: 1000,
            current_bet: 0,
            folded?: false,
            seat_position: nil,
            hand: [],
            connected?: true,
            waiting?: false,
            total_contribution: 0

  def new(player_id, viewer_id, opts \\ []) do
    ready = Keyword.get(opts, :ready?, false)
    chips = Keyword.get(opts, :chips, 1000)
    current_bet = Keyword.get(opts, :current_bet, 0)
    folded = Keyword.get(opts, :folded?, false)
    seat_position = Keyword.get(opts, :seat_position, nil)
    hand = Keyword.get(opts, :hand, [])
    connected = Keyword.get(opts, :connected?, true)
    waiting = Keyword.get(opts, :waiting?, false)
    total_contribution = Keyword.get(opts, :total_contribution, 0)

    %__MODULE__{
      player_id: player_id,
      viewer_id: viewer_id,
      ready?: ready,
      chips: chips,
      current_bet: current_bet,
      folded?: folded,
      seat_position: seat_position,
      hand: hand,
      connected?: connected,
      waiting?: waiting,
      total_contribution: total_contribution
    }
  end

  def change(%__MODULE__{} = player, opts \\ []) do
    updates = Enum.into(opts, %{})
    struct(player, updates)
  end

  def set_ready(%__MODULE__{} = player, ready) do
    %__MODULE__{player | ready?: ready}
  end
end
