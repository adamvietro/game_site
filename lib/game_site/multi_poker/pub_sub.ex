defmodule GameSite.MultiPoker.PubSub do
  alias Phoenix.PubSub

  @pubsub GameSite.PubSub
  @lobby_topic "multi_poker:lobby"

  def lobby_topic, do: @lobby_topic

  def room_topic(room_id), do: "multi_poker:room:#{room_id}"

  def subscribe_lobby do
    PubSub.subscribe(@pubsub, lobby_topic())
  end

  def subscribe_room(room_id) do
    PubSub.subscribe(@pubsub, room_topic(room_id))
  end

  def broadcast_lobby_updated do
    PubSub.broadcast(@pubsub, lobby_topic(), {:lobby_updated})
  end

  def broadcast_room_updated(room) do
    PubSub.broadcast(@pubsub, room_topic(room.room_id), {:room_updated, room})
  end

  def broadcast_room_closed(room_id) do
    PubSub.broadcast(@pubsub, room_topic(room_id), {:room_closed, room_id})
  end
end
