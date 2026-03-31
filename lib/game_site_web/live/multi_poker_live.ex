defmodule GameSiteWeb.MultiPokerLive do
  use GameSiteWeb, :live_view

  alias GameSite.MultiPoker.{GameLogic, Room}
  alias GameSite.MultiPoker
  alias GameSiteWeb.MultiPokerLive.GameBoard

  def render(assigns) do
    ~H"""
    <%= if is_nil(@room) do %>
      Room is loading...
    <% else %>
      <p>Room Status: {@room.room_status}</p>
      <p>Small Blind: {@room.small_blind}</p>
      <p>Big Blind: {@room.big_blind}</p>

      <p>Deck:</p>
      <pre><%= inspect(@room.deck) %></pre>
      <GameBoard.score_board
        phase={@room.phase}
        current_player_turn={@room.current_player_turn}
        pot={@room.pot}
        dealer_player_id={@room.dealer_player_id}
      />

      <GameBoard.game_table
        players={@room.players}
        current_player={@room.current_player_turn}
        community_cards={@room.community_cards}
        current_player_id={@current_user.id}
      />
    <% end %>
    """
  end

  def mount(params, _session, socket) do
    if connected?(socket) do
      case MultiPoker.get_room(params["room"]) do
        {:ok, room} -> {:ok, assign(socket, :room, room)}
        :error -> {:ok, assign(socket, :room, :bad_room)}
      end
    else
      {:ok, assign(socket, :room, nil)}
    end
  end

  def set_current_user_id(%{assigns: %{current_user: current_user}}) do
  end
end
