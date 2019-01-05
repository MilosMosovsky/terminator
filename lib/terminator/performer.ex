defmodule Post do
  defstruct name: "john"
end

defmodule Terminator.Performer do
  @moduledoc """
  Performer is a main actor for determining abilities
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias __MODULE__
  alias Terminator.Ability
  alias Terminator.Repo
  alias Terminator.Role
  alias Terminator.PerformersEntities
  alias Terminator.PerformersRoles

  @typedoc "A performer struct"
  @type t :: %Performer{}

  schema "terminator_performers" do
    field(:abilities, {:array, :string}, default: [])

    many_to_many(:roles, Role, join_through: PerformersRoles)
    has_many(:entities, PerformersEntities)

    timestamps()
  end

  def changeset(%Performer{} = struct, params \\ %{}) do
    struct
    |> cast(params, [])
  end

  @doc """
  Grant given grant type to a performer.

  ## Examples

  Function accepts either `Terminator.Ability` or `Terminator.Role` grants.
  Function is merging existing grants with the new ones, so calling grant with same
  grants will not duplicate entries in table.

  To grant particular ability to a given performer

      iex> Terminator.Performer.grant(%Terminator.Performer{id: 1}, %Terminator.Ability{id: 1})

  To grant particular role to a given performer

      iex> Terminator.Performer.grant(%Terminator.Performer{id: 1}, %Terminator.Role{id: 1})

  """

  @spec grant(Performer.t(), Ability.t() | Role.t()) :: Performer.t()
  def grant(%Performer{id: id} = _performer, %Role{id: _id} = role) do
    # Preload performer roles
    performer = Performer |> Repo.get!(id) |> Repo.preload([:roles])

    roles = merge_uniq_grants(performer.roles ++ [role])

    changeset =
      changeset(performer)
      |> put_assoc(:roles, roles)

    changeset |> Repo.update!()
  end

  def grant(%{performer: %Performer{id: _pid} = performer}, %Role{id: _id} = role) do
    grant(performer, role)
  end

  def grant(%{performer_id: id}, %Role{id: _id} = role) do
    performer = Performer |> Repo.get!(id)
    grant(performer, role)
  end

  def grant(%Performer{id: id} = _performer, %Ability{id: _id} = ability) do
    performer = Performer |> Repo.get!(id)
    abilities = Enum.uniq(performer.abilities ++ [ability.identifier])

    changeset =
      changeset(performer)
      |> put_change(:abilities, abilities)

    changeset |> Repo.update!()
  end

  def grant(%{performer: %Performer{id: id}}, %Ability{id: _id} = ability) do
    performer = Performer |> Repo.get!(id)
    grant(performer, ability)
  end

  def grant(%{performer_id: id}, %Ability{id: _id} = ability) do
    performer = Performer |> Repo.get!(id)
    grant(performer, ability)
  end

  def grant(_, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  def grant(
        %Performer{id: _pid} = performer,
        %Ability{id: _aid} = ability,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    entity_abilities = load_performer_entities(performer, entity)

    case entity_abilities do
      nil ->
        PerformersEntities.create(performer, entity, [ability.identifier])

      entity ->
        abilities = Enum.uniq(entity.abilities ++ [ability.identifier])

        PerformersEntities.changeset(entity)
        |> put_change(:abilities, abilities)
        |> Repo.update!()
    end

    performer
  end

  def grant(
        %{performer_id: id},
        %Ability{id: _id} = ability,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    grant(%Performer{id: id}, ability, entity)
  end

  def grant(
        %{performer: %Performer{id: _pid} = performer},
        %Ability{id: _id} = ability,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    grant(performer, ability, entity)
  end

  def grant(_, _, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  @doc """
  Revoke given grant type from a performer.

  ## Examples

  Function accepts either `Terminator.Ability` or `Terminator.Role` grants.
  Function is directly opposite of `Terminator.Performer.grant/2`

  To revoke particular ability from a given performer

      iex> Terminator.Performer.revoke(%Terminator.Performer{id: 1}, %Terminator.Ability{id: 1})

  To revoke particular role from a given performer

      iex> Terminator.Performer.revoke(%Terminator.Performer{id: 1}, %Terminator.Role{id: 1})

  """
  @spec revoke(Performer.t(), Ability.t() | Role.t()) :: Performer.t()
  def revoke(%Performer{id: id} = _performer, %Role{id: _id} = role) do
    from(pa in PerformersRoles)
    |> where([pr], pr.performer_id == ^id and pr.role_id == ^role.id)
    |> Repo.delete_all()
  end

  def revoke(%{performer: %Performer{id: _pid} = performer}, %Role{id: _id} = role) do
    revoke(performer, role)
  end

  def revoke(%{performer_id: id}, %Role{id: _id} = role) do
    revoke(%Performer{id: id}, role)
  end

  def revoke(%Performer{id: id} = _performer, %Ability{id: _id} = ability) do
    performer = Performer |> Repo.get!(id)

    abilities =
      Enum.filter(performer.abilities, fn grant ->
        grant != ability.identifier
      end)

    changeset =
      changeset(performer)
      |> put_change(:abilities, abilities)

    changeset |> Repo.update!()
  end

  def revoke(
        %{performer: %Performer{id: _pid} = performer},
        %Ability{id: _id} = ability
      ) do
    revoke(performer, ability)
  end

  def revoke(%{performer_id: id}, %Ability{id: _id} = ability) do
    revoke(%Performer{id: id}, ability)
  end

  def revoke(_, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def revoke(
        %Performer{id: _pid} = performer,
        %Ability{id: _id} = ability,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    entity_abilities = load_performer_entities(performer, entity)

    case entity_abilities do
      nil ->
        performer

      entity ->
        abilities =
          Enum.filter(entity.abilities, fn grant ->
            grant != ability.identifier
          end)

        if length(abilities) == 0 do
          entity |> Repo.delete!()
        else
          PerformersEntities.changeset(entity)
          |> put_change(:abilities, abilities)
          |> Repo.update!()
        end

        performer
    end
  end

  def revoke(
        %{performer_id: id},
        %Ability{id: _id} = ability,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    revoke(%Performer{id: id}, ability, entity)
  end

  def revoke(
        %{performer: %Performer{id: _pid} = performer},
        %Ability{id: _id} = ability,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    revoke(performer, ability, entity)
  end

  def revoke(_, _, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def load_performer_entities(performer, %{__struct__: entity_name, id: entity_id}) do
    PerformersEntities
    |> where(
      [e],
      e.performer_id == ^performer.id and e.assoc_id == ^entity_id and
        e.assoc_type == ^PerformersEntities.normalize_struct_name(entity_name)
    )
    |> Repo.one()
  end

  def table, do: :terminator_performers

  defp merge_uniq_grants(grants) do
    Enum.uniq_by(grants, fn grant ->
      grant.identifier
    end)
  end
end
