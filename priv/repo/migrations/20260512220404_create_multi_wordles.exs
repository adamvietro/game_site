defmodule GameSite.Repo.Migrations.CreateMultiWordles do
  use Ecto.Migration

  def change do
    create table(:multi_wordles) do
      add :word, :string
      add :date, :date

      timestamps(type: :utc_datetime)
    end
  end
end
