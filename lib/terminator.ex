defmodule Terminator do
  @moduledoc """
  Main Terminator module for including macros

  Terminator has 3 main components:

    * `Terminator.Ability` - Representation of a single permission e.g. :view, :delete, :update
    * `Terminator.Performer` - Main actor which is holding given abilities
    * `Terminator.Role` - Grouped set of multiple abilities, e.g. :admin, :manager, :editor

  ## Relations between models

  `Terminator.Performer` -> `Terminator.Ability` [1-n] - Any given performer can hold multiple abilities
  this allows you to have very granular set of abilities per each performer

  `Terminator.Performer` -> `Terminator.Role` [1-n] - Any given performer can act as multiple roles
  this allows you to manage multple sets of abilities for multiple performers at once

  `Terminator.Role` -> `Terminator.Ability` [m-n] - Any role can have multiple abilities therefore
  you can have multiple roles to have different/same abilities

  ## Calculating abilities

  Calculation of abilities is done by *OR* and *DISTINCT* abilities. That means if you have

  `Role[:admin, abilities: [:delete]]`, `Role[:editor, abilities: [:update]]`, `Role[:user, abilities: [:view]]`
  and all roles are granted to single performer, resulting abilities will be `[:delete, :update, :view]`


  ## Available permissions

    * `Terminator.has_ability/1` - Requires single ability to be present on performer
    * `Terminator.has_role/1` - Requires single role to be present on performer

  """

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    create_terminator()
  end

  @doc """
  Macro for defining required permissions

  ## Example

      defmodule HelloTest do
        use Terminator

        def test_authorization do
          permissions do
            has_role(:admin)
            has_ability(:view)
          end
        end
      end
  """

  defmacro permissions(do: block) do
    quote do
      reset_session()
      unquote(block)
    end
  end

  @doc """
  Resets ETS table
  """
  def reset_session() do
    Terminator.Registry.insert(:required_abilities, [])
    Terminator.Registry.insert(:required_roles, [])
    Terminator.Registry.insert(:calculated_permissions, [])
    Terminator.Registry.insert(:extra_rules, [])
  end

  @doc """
  Macro for wrapping protected code

  ## Example

      defmodule HelloTest do
        use Terminator

        def test_authorization do
          as_authorized do
            IO.inspect("This code is executed only for authorized performer")
          end
        end
      end
  """

  defmacro as_authorized(do: block) do
    quote do
      with :ok <- perform_authorization!() do
        unquote(block)
      end
    end
  end

  @doc """
  Defines calculated permission to be evaluated in runtime

  ## Examples

      defmodule HelloTest do
        use Terminator

        def test_authorization do
          permissions do
            calculated(fn performer ->
              performer.email_confirmed?
            end)
          end

          as_authorized do
            IO.inspect("This code is executed only for authorized performer")
          end
        end
      end

  You can also use DSL form which takes function name as argument

        defmodule HelloTest do
        use Terminator

        def test_authorization do
          permissions do
            calculated(:email_confirmed)
          end

          as_authorized do
            IO.inspect("This code is executed only for authorized performer")
          end
        end

        def email_confirmed(performer) do
          performer.email_confirmed?
        end
      end

    For more complex calculation you need to pass bindings to the function

        defmodule HelloTest do
        use Terminator

        def test_authorization do
          post = %Post{owner_id: 1}

          permissions do
            calculated(:is_owner, [post])
            calculated(fn performer, [post] ->
              post.owner_id == performer.id
            end)
          end

          as_authorized do
            IO.inspect("This code is executed only for authorized performer")
          end
        end

        def is_owner(performer, [post]) do
          post.owner_id == performer.id
        end
      end

  """
  defmacro calculated(func_name) when is_atom(func_name) do
    quote do
      {:ok, current_performer} = Terminator.Registry.lookup(:current_performer)

      Terminator.Registry.add(
        :calculated_permissions,
        unquote(func_name)(current_performer)
      )
    end
  end

  defmacro calculated(callback) do
    quote do
      {:ok, current_performer} = Terminator.Registry.lookup(:current_performer)

      result = apply(unquote(callback), [current_performer])

      Terminator.Registry.add(
        :calculated_permissions,
        result
      )
    end
  end

  defmacro calculated(func_name, bindings) when is_atom(func_name) do
    quote do
      {:ok, current_performer} = Terminator.Registry.lookup(:current_performer)

      result = unquote(func_name)(current_performer, unquote(bindings))

      Terminator.Registry.add(
        :calculated_permissions,
        result
      )
    end
  end

  defmacro calculated(callback, bindings) do
    quote do
      {:ok, current_performer} = Terminator.Registry.lookup(:current_performer)

      result = apply(unquote(callback), [current_performer, unquote(bindings)])

      Terminator.Registry.add(
        :calculated_permissions,
        result
      )
    end
  end

  @doc ~S"""
  Returns authorization result on collected performer and required roles/abilities

  ## Example

      defmodule HelloTest do
        use Terminator

        def test_authorization do
          case is_authorized? do
            :ok -> "Performer is authorized"
            {:error, message: _message} -> "Performer is not authorized"
        end
      end
  """
  @spec is_authorized?() :: :ok | {:error, String.t()}
  def is_authorized? do
    perform_authorization!()
  end

  @doc """
  Perform authorization on passed performer and abilities
  """
  @spec has_ability?(Terminator.Performer.t(), atom()) :: boolean()
  def has_ability?(%Terminator.Performer{} = performer, ability_name) do
    perform_authorization!(performer, [Atom.to_string(ability_name)], []) == :ok
  end

  def has_ability?(
        %Terminator.Performer{} = performer,
        ability_name,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    active_abilities =
      case Terminator.Performer.load_performer_entities(performer, entity) do
        nil -> []
        entity -> entity.abilities
      end

    Enum.member?(active_abilities, Atom.to_string(ability_name))
  end

  @doc """
  Perform role check on passed performer and role
  """
  def has_role?(%Terminator.Performer{} = performer, role_name) do
    perform_authorization!(performer, nil, [Atom.to_string(role_name)], nil) == :ok
  end

  @doc false
  def perform_authorization!(
        current_performer \\ nil,
        required_abilities \\ [],
        required_roles \\ [],
        extra_rules \\ []
      ) do
    current_performer =
      case current_performer do
        nil ->
          {:ok, current_performer} = Terminator.Registry.lookup(:current_performer)
          current_performer

        _ ->
          current_performer
      end

    required_abilities = ensure_array_from_ets(required_abilities, :required_abilities)
    required_roles = ensure_array_from_ets(required_roles, :required_roles)
    extra_rules = ensure_array_from_ets(extra_rules, :extra_rules)
    calculated_permissions = ensure_array_from_ets([], :calculated_permissions)

    # If no performer is given we can assume that permissions are not granted
    if is_nil(current_performer) do
      {:error, "Performer is not granted to perform this action"}
    else
      # If no permissions were required then we can assume performe is granted
      if length(required_abilities) + length(required_roles) + length(calculated_permissions) +
           length(extra_rules) == 0 do
        :ok
      else
        # 1st layer of authorization (optimize db load)
        first_layer =
          authorize!(
            [
              authorize_abilities(current_performer.abilities, required_abilities)
            ] ++ calculated_permissions ++ extra_rules
          )

        if first_layer == :ok do
          first_layer
        else
          # 2nd layer with DB preloading of roles
          %{roles: current_roles} = load_performer_roles(current_performer)

          second_layer =
            authorize!([
              authorize_roles(current_roles, required_roles),
              authorize_inherited_abilities(current_roles, required_abilities)
            ])

          if second_layer == :ok do
            second_layer
          else
            {:error, "Performer is not granted to perform this action"}
          end
        end
      end
    end
  end

  defp ensure_array_from_ets(value, name) do
    value =
      case value do
        [] ->
          {:ok, value} = Terminator.Registry.lookup(name)
          value

        value ->
          value
      end

    case value do
      nil -> []
      _ -> value
    end
  end

  @doc false
  def create_terminator() do
    quote do
      import Terminator, only: [store_performer!: 1, load_and_store_performer!: 1]

      def load_and_authorize_performer(%Terminator.Performer{id: _id} = performer),
        do: store_performer!(performer)

      def load_and_authorize_performer(%{performer: %Terminator.Performer{id: _id} = performer}),
        do: store_performer!(performer)

      def load_and_authorize_performer(%{performer_id: performer_id})
          when not is_nil(performer_id),
          do: load_and_store_performer!(performer_id)

      def load_and_authorize_performer(performer),
        do: raise(ArgumentError, message: "Invalid performer given #{inspect(performer)}")
    end
  end

  @doc false
  @spec load_and_store_performer!(integer()) :: {:ok, Terminator.Performer.t()}
  def load_and_store_performer!(performer_id) do
    performer = Terminator.Repo.get!(Terminator.Performer, performer_id)
    store_performer!(performer)
  end

  @doc false
  @spec load_performer_roles(Terminator.Performer.t()) :: Terminator.Performer.t()
  def load_performer_roles(performer) do
    performer |> Terminator.Repo.preload([:roles])
  end

  @doc false
  @spec store_performer!(Terminator.Performer.t()) :: {:ok, Terminator.Performer.t()}
  def store_performer!(%Terminator.Performer{id: _id} = performer) do
    Terminator.Registry.insert(:current_performer, performer)
    {:ok, performer}
  end

  @doc false
  def authorize_abilities(active_abilities \\ [], required_abilities \\ []) do
    authorized =
      Enum.filter(required_abilities, fn ability ->
        Enum.member?(active_abilities, ability)
      end)

    length(authorized) > 0
  end

  @doc false
  def authorize_inherited_abilities(active_roles \\ [], required_abilities \\ []) do
    active_abilities =
      active_roles
      |> Enum.map(& &1.abilities)
      |> List.flatten()
      |> Enum.uniq()

    authorized =
      Enum.filter(required_abilities, fn ability ->
        Enum.member?(active_abilities, ability)
      end)

    length(authorized) > 0
  end

  @doc false
  def authorize_roles(active_roles \\ [], required_roles \\ []) do
    active_roles =
      active_roles
      |> Enum.map(& &1.identifier)
      |> Enum.uniq()

    authorized =
      Enum.filter(required_roles, fn role ->
        Enum.member?(active_roles, role)
      end)

    length(authorized) > 0
  end

  @doc false
  def authorize!(conditions) do
    # Authorize empty conditions as true

    conditions =
      case length(conditions) do
        0 -> conditions ++ [true]
        _ -> conditions
      end

    authorized =
      Enum.reduce(conditions, false, fn condition, acc ->
        condition || acc
      end)

    case authorized do
      true -> :ok
      _ -> {:error, "Performer is not granted to perform this action"}
    end
  end

  @doc """
  Requires an ability within permissions block

  ## Example

      defmodule HelloTest do
        use Terminator

        def test_authorization do
          permissions do
            has_ability(:can_run_test_authorization)
          end
        end
      end
  """
  @spec has_ability(atom()) :: {:ok, atom()}
  def has_ability(ability) do
    Terminator.Registry.add(:required_abilities, Atom.to_string(ability))
    {:ok, ability}
  end

  def has_ability(ability, %{__struct__: _entity_name, id: _entity_id} = entity) do
    {:ok, current_performer} = Terminator.Registry.lookup(:current_performer)

    Terminator.Registry.add(:extra_rules, has_ability?(current_performer, ability, entity))
    {:ok, ability}
  end

  @doc """
  Requires a role within permissions block

  ## Example

      defmodule HelloTest do
        use Terminator

        def test_authorization do
          permissions do
            has_role(:admin)
          end
        end
      end
  """
  @spec has_role(atom()) :: {:ok, atom()}
  def has_role(role) do
    Terminator.Registry.add(:required_roles, Atom.to_string(role))
    {:ok, role}
  end
end
