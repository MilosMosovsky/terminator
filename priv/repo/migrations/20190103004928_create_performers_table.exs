defmodule Terminator.Repo.Migrations.CreatePerformersTable do
  use Ecto.Migration

  def change do
    create table(:terminator_performers) do
      add :name, :string

      timestamps()
    end
  end
end
