defmodule Terminator.Repo.Migrations.CreateRolesTable do
  use Ecto.Migration

  def change do
    create table(:terminator_roles) do
      add(:identifier, :string)
      add(:name, :string, size: 255)
      add(:abilities, {:array, :string}, default: [])

      timestamps()
    end

    create(unique_index(:terminator_roles, [:identifier]))
  end
end
