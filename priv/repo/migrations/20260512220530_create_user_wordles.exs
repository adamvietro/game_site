defmodule GameSite.Repo.Migrations.CreateUserWordles do
  use Ecto.Migration

  def change do
    create table(:user_wordles) do
      add :entered_words, {:array, :string}
      add :attempts, :integer
      add :status, :string
      add :completed_at, :utc_datetime
      add :user_id, references(:users, on_delete: :nothing)
      add :multi_wordle_id, references(:multi_wordles, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:user_wordles, [:user_id])
    create index(:user_wordles, [:multi_wordle_id])
  end
end
