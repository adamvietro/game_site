defmodule GameSiteWeb.MultiPokerLive.ComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias GameSiteWeb.MultiPokerLive.Component

  describe "instructions/1" do
    test "renders the poker game overview text" do
      html = render_component(&Component.instructions/1, %{})

      assert html =~ "Poker Game Overview"
      assert html =~ "Here you can create or join a room to play some poker"
      assert html =~ "You must be logged in to create a room."
      assert html =~ "There will be a max of 6 players per room."
      assert html =~ "You will start with 1000 chips if you are a new player."
    end
  end

  describe "live_games/1" do
    test "renders the rooms table with room info and join links" do
      rooms = [
        %{
          room_id: "room-1",
          display_id: "ABCD12",
          player_count: 3,
          room_status: :waiting
        },
        %{
          room_id: "room-2",
          display_id: "EFGH34",
          player_count: 6,
          room_status: :in_progress
        }
      ]

      html = render_component(&Component.live_games/1, %{rooms: rooms})

      assert html =~ "Room"
      assert html =~ "Players"

      assert html =~ "ABCD12"
      assert html =~ "EFGH34"
      assert html =~ "3"
      assert html =~ "6"

      assert html =~ "waiting"
      assert html =~ "in_progress"

      assert html =~ ~s(href="/multi-poker/room-1")
      assert html =~ ~s(href="/multi-poker/room-2")
      assert html =~ "Join"
    end

    test "renders an empty table when there are no rooms" do
      html = render_component(&Component.live_games/1, %{rooms: []})

      assert html =~ "No live rooms"
      refute html =~ ~s(href="/multi-poker/)
    end
  end

  describe "new_game/1" do
    test "renders log in and register links when current_user is nil" do
      html = render_component(&Component.new_game/1, %{current_user: nil})

      assert html =~ "Can't find a game you like?"
      assert html =~ "Log in or create an account to make your own room."
      assert html =~ "Log in"
      assert html =~ "Register"

      assert html =~ ~s(href="/users/log_in")
      assert html =~ ~s(href="/users/register")

      refute html =~ "Create Room"
      refute html =~ ~s(phx-click="create_room")
    end

    test "renders create room button when current_user exists" do
      html = render_component(&Component.new_game/1, %{current_user: %{id: 1}})

      assert html =~ "Can't find a game you like?"
      assert html =~ "Start a new room and invite other players to join."
      assert html =~ "Create Room"
      assert html =~ ~s(phx-click="create_room")

      refute html =~ ~s(href="/users/log_in")
      refute html =~ ~s(href="/users/register")
      refute html =~ "Log in or create an account to make your own room."
    end
  end
end
