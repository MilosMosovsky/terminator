defmodule Terminator.Repo.Migrations.CreatePerformersEntitiesTable do
  use Ecto.Migration

  def change do
    create table(:terminator_performers_entities) do
      add(:performer_id, references(Terminator.Performer.table()))
      add(:assoc_id, :integer)
      add(:assoc_type, :string)
      add(:abilities, {:array, :string})

      timestamps()
    end
  end
end
