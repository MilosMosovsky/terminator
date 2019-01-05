defmodule Terminator.PerformersEntities do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "terminator_performers_entities" do
    belongs_to(:performer, Terminator.Performer)
    field(:assoc_id, :integer)
    field(:assoc_type, :string)
    field(:abilities, {:array, :string}, default: [])

    timestamps()
  end

  def changeset(%PerformersEntities{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:performer_id, :assoc_type, :assoc_id, :abilities])
    |> validate_required([:performer_id, :assoc_type, :assoc_id, :abilities])
  end

  def create(
        %Terminator.Performer{id: id},
        %{__struct__: entity_name, id: entity_id},
        abilities \\ []
      ) do
    changeset(%PerformersEntities{
      performer_id: id,
      assoc_type: entity_name |> normalize_struct_name,
      assoc_id: entity_id,
      abilities: abilities
    })
    |> Terminator.Repo.insert!()
  end

  def normalize_struct_name(name) do
    name
    |> Atom.to_string()
    |> String.replace(".", "_")
    |> String.downcase()
  end
end
