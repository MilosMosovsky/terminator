defmodule Terminator.Guard do
  import Ecto.Query

  defmacro __using__(opts) do
    quote do
      import Terminator.Guard

      def load_and_authorize_performer(%{id: id}) do
        repo = get_repo()
        [performer: performer, role: _] = unquote(opts)

        performer =
          performer
          |> get_resource_by_id(id)
          |> join_role_abilities
          |> repo.one()

        performer = performer |> get_performer_abilities(id)
        performer = performer |> get_performer_entity_abilities(id)

        Terminator.Registry.insert(:current_performer, performer)

        {:ok, performer}
      end

      defp get_resource_by_id(resource, id) do
        resource
        |> where([r], r.id == ^id)
      end

      defp join_role_abilities(query) do
        [performer: _, role: role] = unquote(opts)

        query
        |> join(:left, [u], ur in assoc(u, :roles))
        |> join(:left, [u, ur], r in ^role, on: r.id == ur.role_id)
        |> select([u, ur, r], %{u | role_abilities: r.abilities, roles: [r]})
      end

      defp get_performer_abilities(performer, id) do
        repo = get_repo()

        abilities =
          Api.Ecto.Models.UsersAbilities
          |> where([uab], uab.user_id == ^id)
          |> join(:left, [uab], ab in Api.Ecto.Models.Ability, on: ab.id == uab.ability_id)
          |> where([uab, ab], is_nil(uab.entity_id) and is_nil(uab.entity_type))
          |> select([uab, ab], ab)
          |> repo.all()

        Map.put(performer, :abilities, Enum.map(abilities, & &1.identifier))
      end

      defp get_performer_entity_abilities(performer, id) do
        repo = get_repo()

        abilities =
          Api.Ecto.Models.UsersAbilities
          |> where([uab], uab.user_id == ^id)
          |> join(:left, [uab], ab in Api.Ecto.Models.Ability, on: ab.id == uab.ability_id)
          |> where([uab, ab], not is_nil(uab.entity_id) and not is_nil(uab.entity_type))
          |> select([uab, ab], %{
            identifier: ab.identifier,
            entity_type: uab.entity_type,
            entity_id: uab.entity_id
          })
          |> repo.all()

        Map.put(performer, :entity_abilities, abilities)
      end

      defp merge_joins(query) do
        query
        |> select([u, _, r, _, ab], %{u | role_abilities: r.abilities, roles: [r]})
      end

      defp get_repo() do
        Application.get_env(:terminator, :ecto_repo)
      end

      def authorize_abilities!(abilities, s_abilities) do
        abilities =
          case abilities do
            nil -> []
            _ -> abilities
          end

        s_abilities =
          case s_abilities do
            nil -> []
            _ -> s_abilities
          end

        result =
          Enum.filter(abilities, fn el ->
            Enum.member?(s_abilities, el) || Enum.member?(s_abilities, Atom.to_string(el))
          end)

        length(result) > 0
      end

      def authorize_resource!(abilities, s_abilities) do
        Enum.reduce(abilities, false, fn ability, acc ->
          {ability, entity} = ability

          matched_abilities =
            Enum.filter(s_abilities, fn s_ability ->
              s_ability.entity_id == entity.id && s_ability.entity_type == entity.__meta__.source &&
                s_ability.identifier == Atom.to_string(ability)
            end)

          length(matched_abilities) > 0 || acc
        end)
      end

      def can?(conditions) do
        can = false

        can =
          Enum.reduce(conditions, can, fn condition, acc ->
            condition || acc
          end)

        if can do
          :ok
        else
          {:error, "Subject is not allowed to perform this action"}
        end
      end
    end
  end

  defmacro preconditions(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro as_authorized(do: block) do
    quote do
      {:ok, performer} = Terminator.Registry.lookup(:current_performer)
      {:ok, abilities} = Terminator.Registry.lookup(:abilities)
      {:ok, roles} = Terminator.Registry.lookup(:roles)
      {:ok, resource_abilities} = Terminator.Registry.lookup(:resource_abilities)

      if is_nil(performer) do
        {:error, "Subject is not allowed to perform this action"}
      else
        with :ok <-
               can?([
                 authorize_abilities!(abilities, performer.role_abilities),
                 authorize_abilities!(abilities, performer.abilities),
                 authorize_abilities!(roles, Enum.map(performer.roles, & &1.identifier)),
                 authorize_resource!(resource_abilities, performer.entity_abilities)
               ]) do
          unquote(block)
        end
      end
    end
  end

  def ability(name) do
    Terminator.Registry.add(:abilities, [name])
  end

  def ability(name, resource) do
    Terminator.Registry.add(:resource_abilities, [{name, resource}])
  end

  def role(name) do
    Terminator.Registry.add(:roles, [name])
  end
end
