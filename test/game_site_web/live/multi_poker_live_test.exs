defmodule GameSiteWeb.MultiPokerLiveTest do
  use ExUnit.Case, async: false

  alias GameSite.MultiPoker
  alias GameSite.MultiPoker.{Room, Player}
  alias GameSiteWeb.MultiPokerLive

  defp build_socket(assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns:
        assigns
        |> Map.put_new(:__changed__, %{})
        |> Map.put_new(:flash, %{})
    }
  end

  defp unique_guest_id() do
    "guest-" <> Integer.to_string(System.unique_integer([:positive]))
  end

  defp unique_user_viewer_id() do
    "user:test-" <> Integer.to_string(System.unique_integer([:positive]))
  end

  defp create_room!(viewer_id) do
    case MultiPoker.create_room(viewer_id) do
      {:ok, room_id} ->
        room_id

      {:error, :already_has_room, room_id} ->
        room_id
    end
  end

  defp get_room!(room_id) do
    {:ok, room} = MultiPoker.get_room(room_id)
    room
  end

  describe "set_current_viewer_id/2" do
    test "sets signed in user viewer id" do
      socket = build_socket(%{current_user: %{id: 123}})

      updated_socket = MultiPokerLive.set_current_viewer_id(socket, %{})

      assert updated_socket.assigns.current_viewer_id == "user:123"
    end

    test "sets guest viewer id when there is no current user" do
      socket = build_socket(%{current_user: nil})

      updated_socket = MultiPokerLive.set_current_viewer_id(socket, %{"guest_id" => "abc123"})

      assert updated_socket.assigns.current_viewer_id == "guest:abc123"
    end

    test "sets guest viewer id when current_user assign is missing" do
      socket = build_socket()

      updated_socket =
        MultiPokerLive.set_current_viewer_id(socket, %{"guest_id" => "missing-user"})

      assert updated_socket.assigns.current_viewer_id == "guest:missing-user"
    end
  end

  describe "mount/3" do
    test "loads room and viewer state for a signed in user" do
      viewer_id = unique_user_viewer_id()
      room_id = create_room!(viewer_id)

      socket =
        build_socket(%{current_user: %{id: String.replace_prefix(viewer_id, "user:test-", "")}})

      {:ok, mounted_socket} =
        MultiPokerLive.mount(%{"room" => room_id}, %{}, socket)

      assert mounted_socket.assigns.current_viewer_id =~ "user:"
      assert mounted_socket.assigns.room.room_id == room_id
      assert mounted_socket.assigns.viewer_state != nil
      assert mounted_socket.assigns.form != nil
    end

    test "loads room and viewer state for a guest" do
      guest_id = unique_guest_id()
      room_id = create_room!("guest:" <> guest_id)

      socket = build_socket()

      {:ok, mounted_socket} =
        MultiPokerLive.mount(%{"room" => room_id}, %{"guest_id" => guest_id}, socket)

      assert mounted_socket.assigns.current_viewer_id == "guest:#{guest_id}"
      assert mounted_socket.assigns.room.room_id == room_id
      assert mounted_socket.assigns.viewer_state != nil
      assert mounted_socket.assigns.form != nil
    end

    test "redirects when room does not exist" do
      socket = build_socket()

      {:ok, mounted_socket} =
        MultiPokerLive.mount(
          %{"room" => "does-not-exist"},
          %{"guest_id" => unique_guest_id()},
          socket
        )

      assert mounted_socket.assigns.flash["error"] == "That room does not exist."

      assert match?(
               {:live, :redirect, %{kind: :push, to: "/multi-poker"}},
               mounted_socket.redirected
             )
    end
  end

  describe "handle_info/2" do
    test "room_updated assigns the latest room and viewer_state" do
      guest_id = unique_guest_id()
      viewer_id = "guest:#{guest_id}"
      room_id = create_room!(viewer_id)
      room = get_room!(room_id)

      socket =
        build_socket(%{
          current_viewer_id: viewer_id,
          room: room,
          viewer_state: Room.viewer_state(room, viewer_id)
        })

      MultiPoker.player_ready(room_id, viewer_id)
      updated_room = get_room!(room_id)

      assert updated_room.players |> Map.values() |> Enum.any?(& &1.ready?)

      {:noreply, new_socket} = MultiPokerLive.handle_info({:room_updated, updated_room}, socket)

      assert new_socket.assigns.room == updated_room
      assert new_socket.assigns.viewer_state == Room.viewer_state(updated_room, viewer_id)
    end

    test "room_closed pushes navigate back to lobby" do
      socket = build_socket()

      {:noreply, new_socket} = MultiPokerLive.handle_info({:room_closed, "room-1"}, socket)

      assert match?({:live, :redirect, %{kind: :push, to: "/multi-poker"}}, new_socket.redirected)
    end
  end

  describe "handle_event/3" do
    test "player-ready marks player ready" do
      guest_id = unique_guest_id()
      viewer_id = "guest:#{guest_id}"
      room_id = create_room!(viewer_id)
      room = get_room!(room_id)

      socket =
        build_socket(%{
          current_viewer_id: viewer_id,
          room: room
        })

      {:noreply, returned_socket} = MultiPokerLive.handle_event("player-ready", %{}, socket)

      assert returned_socket == socket

      updated_room = get_room!(room_id)
      player = Room.get_player_by_viewer_id_from_room(updated_room, viewer_id)

      assert player.ready? == true
    end

    test "join-game adds a guest player to the room" do
      host_viewer_id = unique_user_viewer_id()
      room_id = create_room!(host_viewer_id)
      room = get_room!(room_id)

      guest_viewer_id = "guest:#{unique_guest_id()}"

      socket =
        build_socket(%{
          current_viewer_id: guest_viewer_id,
          room: room
        })

      {:noreply, returned_socket} = MultiPokerLive.handle_event("join-game", %{}, socket)

      assert returned_socket == socket

      updated_room = get_room!(room_id)
      player = Room.get_player_by_viewer_id_from_room(updated_room, guest_viewer_id)

      assert player != nil
    end

    test "leave-game removes the player from the room" do
      host_viewer_id = unique_user_viewer_id()
      room_id = create_room!(host_viewer_id)

      guest_viewer_id = "guest:#{unique_guest_id()}"
      :ok = MultiPoker.player_add(room_id, guest_viewer_id)

      room = get_room!(room_id)

      assert Room.get_player_by_viewer_id_from_room(room, guest_viewer_id) != nil

      socket =
        build_socket(%{
          current_viewer_id: guest_viewer_id,
          room: room
        })

      {:noreply, returned_socket} = MultiPokerLive.handle_event("leave-game", %{}, socket)

      assert returned_socket == socket

      updated_room = get_room!(room_id)
      assert Room.get_player_by_viewer_id_from_room(updated_room, guest_viewer_id) == nil
    end

    test "player-bet sends bet to game logic" do
      host_viewer_id = unique_user_viewer_id()
      room_id = create_room!(host_viewer_id)

      second_viewer_id = "guest:#{unique_guest_id()}"
      :ok = MultiPoker.player_add(room_id, second_viewer_id)
      :ok = MultiPoker.player_ready(room_id, host_viewer_id)
      :ok = MultiPoker.player_ready(room_id, second_viewer_id)

      room = get_room!(room_id)

      current_turn_player =
        room.players
        |> Map.values()
        |> Enum.find(fn player -> player.player_id == room.current_player_turn end)

      current_turn_viewer_id = current_turn_player.viewer_id

      socket =
        build_socket(%{
          current_viewer_id: current_turn_viewer_id,
          room: room
        })

      player_before = Room.get_player_by_viewer_id_from_room(room, current_turn_viewer_id)

      {:noreply, returned_socket} =
        MultiPokerLive.handle_event("player-bet", %{"bet_amount" => "50"}, socket)

      assert returned_socket == socket

      updated_room = get_room!(room_id)
      player_after = Room.get_player_by_viewer_id_from_room(updated_room, current_turn_viewer_id)

      assert player_after.current_bet >= player_before.current_bet + 50
      assert player_after.chips == player_before.chips - 50
    end

    test "player-fold sends fold to game logic" do
      host_viewer_id = unique_user_viewer_id()
      room_id = create_room!(host_viewer_id)

      second_viewer_id = "guest:#{unique_guest_id()}"
      :ok = MultiPoker.player_add(room_id, second_viewer_id)
      :ok = MultiPoker.player_ready(room_id, host_viewer_id)
      :ok = MultiPoker.player_ready(room_id, second_viewer_id)

      room = get_room!(room_id)

      current_turn_player =
        room.players
        |> Map.values()
        |> Enum.find(fn player -> player.player_id == room.current_player_turn end)

      current_turn_viewer_id = current_turn_player.viewer_id

      socket =
        build_socket(%{
          current_viewer_id: current_turn_viewer_id,
          room: room
        })

      {:noreply, returned_socket} =
        MultiPokerLive.handle_event("player-fold", %{}, socket)

      assert returned_socket == socket

      updated_room = get_room!(room_id)
      folded_player = Room.get_player_by_viewer_id_from_room(updated_room, current_turn_viewer_id)

      assert folded_player.folded? == true or updated_room.room_status == :waiting
    end

    test "player-check sends check to game logic" do
      host_viewer_id = unique_user_viewer_id()
      room_id = create_room!(host_viewer_id)

      second_viewer_id = "guest:#{unique_guest_id()}"
      :ok = MultiPoker.player_add(room_id, second_viewer_id)
      :ok = MultiPoker.player_ready(room_id, host_viewer_id)
      :ok = MultiPoker.player_ready(room_id, second_viewer_id)

      room = get_room!(room_id)

      current_turn_player =
        room.players
        |> Map.values()
        |> Enum.find(fn player -> player.player_id == room.current_player_turn end)

      current_turn_viewer_id = current_turn_player.viewer_id

      room =
        if room.current_round_max_bet == 0 do
          room
        else
          updated_players =
            Map.update!(room.players, current_turn_player.player_id, fn player ->
              Player.change(player, current_bet: room.current_round_max_bet)
            end)

          Room.change(room, players: updated_players)
        end

      socket =
        build_socket(%{
          current_viewer_id: current_turn_viewer_id,
          room: room
        })

      {:noreply, returned_socket} =
        MultiPokerLive.handle_event("player-check", %{}, socket)

      assert returned_socket == socket
    end

    test "player-all-in sends all in to game logic" do
      host_viewer_id = unique_user_viewer_id()
      room_id = create_room!(host_viewer_id)

      second_viewer_id = "guest:#{unique_guest_id()}"
      :ok = MultiPoker.player_add(room_id, second_viewer_id)
      :ok = MultiPoker.player_ready(room_id, host_viewer_id)
      :ok = MultiPoker.player_ready(room_id, second_viewer_id)

      room = get_room!(room_id)

      current_turn_player =
        room.players
        |> Map.values()
        |> Enum.find(fn player -> player.player_id == room.current_player_turn end)

      current_turn_viewer_id = current_turn_player.viewer_id

      socket =
        build_socket(%{
          current_viewer_id: current_turn_viewer_id,
          room: room
        })

      player_before = Room.get_player_by_viewer_id_from_room(room, current_turn_viewer_id)

      {:noreply, returned_socket} =
        MultiPokerLive.handle_event("player-all-in", %{}, socket)

      assert returned_socket == socket

      updated_room = get_room!(room_id)
      player_after = Room.get_player_by_viewer_id_from_room(updated_room, current_turn_viewer_id)

      assert player_after.chips == 0
      assert player_after.current_bet >= player_before.current_bet
    end
  end
end
