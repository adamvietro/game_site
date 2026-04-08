defmodule GameSiteWeb.RockPaperScissorsLive.GameLogicTest do
  use ExUnit.Case, async: true

  alias GameSite.RockPaperScissors.GameLogic

  describe "parse_wager/1" do
    test "returns 1 for blank string" do
      assert GameLogic.parse_wager("") == 1
    end

    test "returns 1 for nil" do
      assert GameLogic.parse_wager(nil) == 1
    end

    test "parses a valid integer string" do
      assert GameLogic.parse_wager("7") == 7
    end
  end

  describe "set_computer_choice/0" do
    test "returns a valid computer choice" do
      assert GameLogic.set_computer_choice() in ["rock", "paper", "scissor"]
    end
  end

  describe "determine_round/1" do
    test "win increases score, updates highest_score, and sets win message" do
      game_state = %GameLogic{
        player: "rock",
        computer: "scissor",
        wager: 3,
        score: 10,
        highest_score: 8
      }

      result = GameLogic.determine_round(game_state)

      assert result.score == 13
      assert result.highest_score == 13
      assert result.message == "You Win!!"
      assert result.outcome == nil
      assert result.wager == 3
      assert result.computer in ["rock", "paper", "scissor"]
    end

    test "lose decreases score and keeps highest_score when not exceeded" do
      game_state = %GameLogic{
        player: "rock",
        computer: "paper",
        wager: 3,
        score: 10,
        highest_score: 20
      }

      result = GameLogic.determine_round(game_state)

      assert result.score == 7
      assert result.highest_score == 20
      assert result.message == "You Lose!!"
      assert result.outcome == nil
      assert result.wager == 3
      assert result.computer in ["rock", "paper", "scissor"]
    end

    test "tie leaves score unchanged" do
      game_state = %GameLogic{
        player: "rock",
        computer: "rock",
        wager: 3,
        score: 10,
        highest_score: 12
      }

      result = GameLogic.determine_round(game_state)

      assert result.score == 10
      assert result.highest_score == 12
      assert result.message == "You Tie!!"
      assert result.outcome == nil
      assert result.wager == 3
      assert result.computer in ["rock", "paper", "scissor"]
    end

    test "losing to zero resets score to 10, wager to 1, and sets flash message" do
      game_state = %GameLogic{
        player: "rock",
        computer: "paper",
        wager: 3,
        score: 3,
        highest_score: 15
      }

      result = GameLogic.determine_round(game_state)

      assert result.score == 10
      assert result.highest_score == 15
      assert result.flash_message == "Score at 0, resetting."
      assert result.message == ""
      assert result.outcome == nil
      assert result.wager == 1
      assert result.computer in ["rock", "paper", "scissor"]
    end

    test "wager is reduced to score when wager is larger than resulting score" do
      game_state = %GameLogic{
        player: "rock",
        computer: "scissor",
        wager: 20,
        score: 10,
        highest_score: 0
      }

      result = GameLogic.determine_round(game_state)

      assert result.score == 30
      assert result.highest_score == 30
      assert result.wager == 20
    end

    test "after a loss wager becomes min of previous wager and resulting score" do
      game_state = %GameLogic{
        player: "rock",
        computer: "paper",
        wager: 8,
        score: 10,
        highest_score: 0
      }

      result = GameLogic.determine_round(game_state)

      assert result.score == 2
      assert result.wager == 2
      assert result.message == "You Lose!!"
    end
  end
end
