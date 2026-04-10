defmodule GameSite.MultiPoker.PubSubTest do
  use ExUnit.Case, async: true

  alias GameSite.MultiPoker.{Player, PubSub, Room}

  describe "topic helpers" do
    test "lobby_topic/0 returns the lobby topic" do
      assert PubSub.lobby_topic() == "multi_poker:lobby"
    end

    test "room_topic/1 returns the room topic for a room id" do
      assert PubSub.room_topic("abc-123") == "multi_poker:room:abc-123"
    end
  end

  describe "lobby pubsub" do
    test "subscribe_lobby/0 subscribes current process to lobby updates" do
      assert :ok = PubSub.subscribe_lobby()

      assert :ok = PubSub.broadcast_lobby_updated()

      assert_receive {:lobby_updated}
    end
  end

  describe "room pubsub" do
    test "subscribe_room/1 subscribes current process to room updates" do
      room_id = "room-1"

      host = Player.new(1, 1)
      room = Room.new(host, room_id: room_id)

      assert :ok = PubSub.subscribe_room(room_id)

      assert :ok = PubSub.broadcast_room_updated(room)

      assert_receive {:room_updated, ^room}
    end

    test "broadcast_room_closed/1 sends room closed message to room subscribers" do
      room_id = "room-2"

      assert :ok = PubSub.subscribe_room(room_id)

      assert :ok = PubSub.broadcast_room_closed(room_id)

      assert_receive {:room_closed, ^room_id}
    end

    test "room subscribers do not receive messages for a different room" do
      subscribed_room_id = "room-1"
      other_room_id = "room-2"

      host = Player.new(1, 1)
      other_room = Room.new(host, room_id: other_room_id)

      assert :ok = PubSub.subscribe_room(subscribed_room_id)

      assert :ok = PubSub.broadcast_room_updated(other_room)
      assert :ok = PubSub.broadcast_room_closed(other_room_id)

      refute_receive {:room_updated, _}
      refute_receive {:room_closed, ^other_room_id}
    end
  end
end
