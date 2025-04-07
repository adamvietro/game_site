defmodule GameSite.Repo.Migrations.CreateScores do
  use Ecto.Migration

  def change do
    create table(:scores) do
      add :score, :integer
      add :user_id, references(:users, on_delete: :delete_all)
      add :game_id, references(:games, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
  end
end
