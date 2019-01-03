defmodule Terminator.Repo.Migrations.CreateAbilitiesTable do
  use Ecto.Migration

  def change do
    create table(:terminator_abilities) do
      add(:identifier, :string)
      add(:name, :string, size: 255)

      timestamps()
    end

    create(unique_index(:terminator_abilities, [:identifier]))
  end
end
