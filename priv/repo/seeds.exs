# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     GameSite.Repo.insert!(%GameSite.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

{:ok, user} =
  PicChat.Accounts.register_user(%{
    email: "test@test.test",
    password: "testtesttest",
    subscribed: true
  })

for n <- ["Guessing Game", "Math Game", ] do
  GameSite.Game.create_game(%{game: n})
end
