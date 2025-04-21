defmodule GameSite.ScoresTest do
  use GameSite.DataCase

  alias GameSite.Scores

  import GameSite.ScoresFixtures
  import GameSite.AccountsFixtures
  import GameSite.GamesFixtures

  describe "scores" do
    alias GameSite.Scores.Score

    @invalid_attrs %{score: nil, game_id: nil, user_id: nil}

    setup do
      user = user_fixture()
      game = game_fixture()

      score =
        score_fixture(%{user_id: user.id, game_id: game.id})

      %{score: score}
    end

    test "list_scores/0 returns all scores", %{score: score} do
      score =
        score
        |> Repo.preload([:user, :game])

      assert Scores.list_scores() == [score]
    end

    test "get_score!/1 returns the score with given id", %{score: score} do
      assert Scores.get_score!(score.id) == score
    end

    test "create_score/1 with duplicate score fails", %{score: score} do
      valid_attrs =
        score
        |> Repo.preload([:user, :game])

      assert {:duplicate, :already_exists} = Scores.create_score(valid_attrs)
      assert score.score == 42
    end

    test "create_score/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Scores.create_score(@invalid_attrs)
    end

    test "update_score/2 with valid data updates the score", %{score: score} do
      update_attrs = %{score: 43}

      assert {:ok, %Score{} = score} = Scores.update_score(score, update_attrs)
      assert score.score == 43
    end

    test "update_score/2 with invalid data returns error changeset", %{score: score} do
      assert {:error, %Ecto.Changeset{}} = Scores.update_score(score, @invalid_attrs)
      assert score == Scores.get_score!(score.id)
    end

    test "delete_score/1 deletes the score", %{score: score} do
      assert {:ok, %Score{}} = Scores.delete_score(score)
      assert_raise Ecto.NoResultsError, fn -> Scores.get_score!(score.id) end
    end

    test "change_score/1 returns a score changeset", %{score: score} do
      assert %Ecto.Changeset{} = Scores.change_score(score)
    end
  end
end
