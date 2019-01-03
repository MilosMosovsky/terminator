defmodule Terminator.Repo.Migrations.CreatePerformersAbilitiesTable do
  use Ecto.Migration

  def change do
    create table(:terminator_performers_abilities) do
      add(:performer_id, references(:terminator_performers))
      add(:ability_id, references(:terminator_abilities))

      timestamps()
    end
  end
end
