defmodule Terminator.Repo.Migrations.SetupTables do
  use Ecto.Migration

  def change do
    create table(:terminator_performers) do
      add(:abilities, {:array, :string}, default: [])

      timestamps()
    end

    create table(:terminator_roles) do
      add(:identifier, :string)
      add(:name, :string, size: 255)
      add(:abilities, {:array, :string}, default: [])

      timestamps()
    end

    create(unique_index(:terminator_roles, [:identifier]))

    create table(:terminator_performers_roles) do
      add(:performer_id, references(:terminator_performers))
      add(:role_id, references(:terminator_roles))

      timestamps()
    end

    create table(:terminator_abilities) do
      add(:identifier, :string)
      add(:name, :string, size: 255)

      timestamps()
    end

    create(unique_index(:terminator_abilities, [:identifier]))

    create table(:terminator_performers_entities) do
      add(:performer_id, references(Terminator.Performer.table()))
      add(:assoc_id, :integer)
      add(:assoc_type, :string)
      add(:abilities, {:array, :string})

      timestamps()
    end
  end
end
