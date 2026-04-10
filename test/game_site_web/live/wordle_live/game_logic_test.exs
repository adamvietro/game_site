defmodule GameSite.Wordle.GameLogicTest do
  use ExUnit.Case, async: true

  alias GameSite.Wordle.GameLogic

  describe "new/1" do
    test "creates default game state" do
      game = GameLogic.new()

      assert game.score == 0
      assert game.round == 0
      assert game.word == ""
      assert game.win? == false
    end

    test "overrides default values" do
      game = GameLogic.new(%{score: 50, word: "apple"})

      assert game.score == 50
      assert game.word == "apple"
    end
  end

  describe "new/2" do
    test "sets guess_string" do
      game = GameLogic.new(%{}, "hello")

      assert game.guess_string == "hello"
    end
  end

  describe "to_map/1" do
    test "converts struct to map" do
      game = GameLogic.new(%{score: 10})

      map = GameLogic.to_map(game)

      assert is_map(map)
      assert map.score == 10
    end
  end

  describe "determine_round/1" do
    test "sets error when word is invalid" do
      game =
        GameLogic.new(%{
          guess_string: "zzzzz",
          word: "apple"
        })

      result = GameLogic.determine_round(game)

      assert result.errors == "Not a valid word"
    end

    test "increments round when guess is valid and incorrect" do
      game =
        GameLogic.new(%{
          guess_string: "grape",
          word: "apple",
          round: 0
        })

      result = GameLogic.determine_round(game)

      assert result.round == 1
      assert result.win? == false
    end

    test "sets win when guess matches word" do
      game =
        GameLogic.new(%{
          guess_string: "apple",
          word: "apple",
          round: 2,
          score: 0,
          current_streak: 0,
          highest_streak: 0
        })

      result = GameLogic.determine_round(game)

      assert result.reset == true
      assert result.current_streak == 1
      assert result.score > 0
    end

    test "resets game when max rounds reached and not won" do
      game =
        GameLogic.new(%{
          guess_string: "grape",
          word: "apple",
          round: 5,
          score: 50,
          current_streak: 3
        })

      result = GameLogic.determine_round(game)

      assert result.reset == true
      assert result.score == 0
      assert result.current_streak == 0
      assert result.round == 0
    end
  end
end
