defmodule Terminator.Repo.Migrations.CreatePerformersTable do
  use Ecto.Migration

  def change do
    create table(:terminator_performers) do
      add(:assoc_id, :integer)

      timestamps()
    end

    create(unique_index(:terminator_performers, [:assoc_id]))
  end
end
