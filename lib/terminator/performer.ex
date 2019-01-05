defmodule Terminator.Performer do
  @moduledoc """
  Performer is a main actor for determining abilities
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias __MODULE__

  @typedoc "A performer struct"
  @type t :: %Performer{}

  schema "terminator_performers" do
    field(:abilities, {:array, :string}, default: [])

    many_to_many(:roles, Terminator.Role, join_through: Terminator.PerformersRoles)

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

  @spec grant(Performer.t(), Terminator.Ability.t() | Terminator.Role.t()) :: Performer.t()
  def grant(%Performer{id: id} = _performer, %Terminator.Role{id: _id} = role) do
    # Preload performer roles
    performer = Performer |> Terminator.Repo.get!(id) |> Terminator.Repo.preload([:roles])

    roles = merge_uniq_grants(performer.roles ++ [role])

    changeset =
      changeset(performer)
      |> put_assoc(:roles, roles)

    changeset |> Terminator.Repo.update!()
  end

  def grant(%Performer{id: id} = _performer, %Terminator.Ability{id: _id} = ability) do
    performer = Performer |> Terminator.Repo.get!(id)
    abilities = Enum.uniq(performer.abilities ++ [ability.identifier])

    changeset =
      changeset(performer)
      |> put_change(:abilities, abilities)

    changeset |> Terminator.Repo.update!()
  end

  def grant(_, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

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
  @spec revoke(Performer.t(), Terminator.Ability.t() | Terminator.Role.t()) :: {integer(), any()}
  def revoke(%Performer{id: id} = _performer, %Terminator.Role{id: _id} = role) do
    from(pa in Terminator.PerformersRoles)
    |> where([pr], pr.performer_id == ^id and pr.role_id == ^role.id)
    |> Terminator.Repo.delete_all()
  end

  def revoke(%Performer{id: id} = _performer, %Terminator.Ability{id: _id} = ability) do
    performer = Performer |> Terminator.Repo.get!(id)

    abilities =
      Enum.filter(performer.abilities, fn grant ->
        grant != ability.identifier
      end)

    changeset =
      changeset(performer)
      |> put_change(:abilities, abilities)

    changeset |> Terminator.Repo.update!()
  end

  def revoke(_, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def table, do: :terminator_performers

  defp merge_uniq_grants(grants) do
    Enum.uniq_by(grants, fn grant ->
      grant.identifier
    end)
  end

  # defp revoke_grants(grants, revoke) do
  #   Enum.filter(grants, fn grant ->
  #     grant.identifier != revoke.identifier
  #   end)
  # end
end
