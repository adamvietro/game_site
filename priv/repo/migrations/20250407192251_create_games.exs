defmodule GameSite.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :name, :text

      timestamps(type: :utc_datetime)
    end
  end
end
