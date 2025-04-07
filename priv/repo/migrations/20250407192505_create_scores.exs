defmodule GameSite.Repo.Migrations.CreateScores do
  use Ecto.Migration

  def change do
    create table(:scores) do
      add :score, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
