defmodule GameSite.Scores do
  @moduledoc """
  The Scores context.
  """

  import Ecto.Query, warn: false
  alias GameSite.Repo

  alias GameSite.Scores.Score

  @doc """
  Returns the list of scores.

  ## Examples

      iex> list_scores()
      [%Score{}, ...]

  """
  def list_scores do
    Repo.all(Score)
    |> Repo.preload([:user, :game])
  end

  def list_scores_sorted do
    from(s in Score,
      order_by: [asc: s.game_id, desc: s.score],
      preload: [:user, :game]
    )
    |> Repo.all()
  end

  def list_top_scores_per_user_per_game do
    max_scores_query =
      from s in Score,
        select: %{
          user_id: s.user_id,
          game_id: s.game_id,
          max_score: max(s.score)
        },
        group_by: [s.user_id, s.game_id]

    query =
      from s in Score,
        join: ms in subquery(max_scores_query),
        on:
          s.user_id == ms.user_id and
            s.game_id == ms.game_id and
            s.score == ms.max_score,
        preload: [:user, :game],
        order_by: [asc: s.game_id, asc: s.user_id]

    Repo.all(query)
  end

  @doc """
  Gets a single score.

  Raises `Ecto.NoResultsError` if the Score does not exist.

  ## Examples

      iex> get_score!(123)
      %Score{}

      iex> get_score!(456)
      ** (Ecto.NoResultsError)

  """
  def get_score!(id), do: Repo.get!(Score, id)

  @doc """
  Creates a score.

  ## Examples

      iex> create_score(%{field: value})
      {:ok, %Score{}}

      iex> create_score(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_score(%{"user_id" => user_id, "game_id" => game_id, "score" => score} = attrs) do
    if is_nil(score) or is_nil(game_id) or is_nil(user_id) do
      {:error, %Ecto.Changeset{}}
    else
      existing_score =
        Repo.get_by(Score,
          user_id: user_id,
          game_id: game_id,
          score: score
        )

      if existing_score do
        {:duplicate, :already_exists}
      else
        %Score{}
        |> Score.changeset(attrs)
        |> Repo.insert()
      end
    end
  end

  @doc """
  Updates a score.

  ## Examples

      iex> update_score(score, %{field: new_value})
      {:ok, %Score{}}

      iex> update_score(score, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_score(%Score{} = score, attrs) do
    score
    |> Score.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a score.

  ## Examples

      iex> delete_score(score)
      {:ok, %Score{}}

      iex> delete_score(score)
      {:error, %Ecto.Changeset{}}

  """
  def delete_score(%Score{} = score) do
    Repo.delete(score)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking score changes.

  ## Examples

      iex> change_score(score)
      %Ecto.Changeset{data: %Score{}}

  """
  def change_score(%Score{} = score, attrs \\ %{}) do
    Score.changeset(score, attrs)
  end

  @doc """
  Returns a list of scores filtered by the given options.

  ## Examples

      iex> list_scores_filtered(%{"game_id" => 1, "sort" => "asc", "limit" => "5"})
      [%Score{}, ...]
  """
  def list_scores_filtered(opts \\ %{}) do
    game_id = Map.get(opts, "game_id")
    sort = Map.get(opts, "sort", "desc")
    limit = Map.get(opts, "limit", "10")
    user_id = Map.get(opts, "user_id")

    Score
    |> maybe_filter_game(game_id)
    |> maybe_filter_user(user_id)
    |> order_scores(sort)
    |> limit_scores(limit)
    |> preload([:user, :game])
    |> Repo.all()
  end

  defp maybe_filter_game(query, nil), do: query
  defp maybe_filter_game(query, ""), do: query

  defp maybe_filter_game(query, game_id) do
    from s in query,
      where: s.game_id == ^game_id
  end

  defp maybe_filter_user(query, nil), do: query
  defp maybe_filter_user(query, ""), do: query

  defp maybe_filter_user(query, user_id) do
    from s in query,
      where: s.user_id == ^user_id
  end

  defp order_scores(query, "asc") do
    from s in query,
      order_by: [asc: s.score]
  end

  defp order_scores(query, _desc) do
    from s in query,
      order_by: [desc: s.score]
  end

  defp limit_scores(query, nil), do: query
  defp limit_scores(query, ""), do: query

  defp limit_scores(query, limit) when is_binary(limit) do
    limit_scores(query, String.to_integer(limit))
  end

  defp limit_scores(query, limit) when is_integer(limit) do
    from s in query,
      limit: ^limit
  end
end
