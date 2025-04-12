defmodule GameSite.Repo.Migrations.AddInUserName do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :user_name, :string, null: false
    end
  end
end
