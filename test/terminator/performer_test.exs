defmodule Terminator.PerformerTest do
  use Terminator.EctoCase
  alias Terminator.Performer

  setup do
    Terminator.reset_session()
    :ok
  end

  describe "Terminator.Performer.changeset/2" do
    test "changeset is valid" do
      changeset = Performer.changeset(%Performer{}, %{})

      assert changeset.valid?
    end
  end

  describe "Terminator.Performer.grant/2" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Performer.grant(nil, nil)
      end
    end

    test "grant ability to performer" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "delete_accounts")

      Performer.grant(performer, ability)

      performer = Repo.get(Performer, performer.id)

      assert 1 == length(performer.abilities)
      assert "delete_accounts" == Enum.at(performer.abilities, 0)
    end

    test "grant ability to inherited performer" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "delete_accounts")

      Performer.grant(%{performer: performer}, ability)

      performer = Repo.get(Performer, performer.id)

      assert 1 == length(performer.abilities)
      assert "delete_accounts" == Enum.at(performer.abilities, 0)
    end

    test "grant ability to inherited performer from id" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "delete_accounts")

      Performer.grant(%{performer_id: performer.id}, ability)

      performer = Repo.get(Performer, performer.id)

      assert 1 == length(performer.abilities)
      assert "delete_accounts" == Enum.at(performer.abilities, 0)
    end

    test "grant only unique abilities to performer" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "delete_accounts")

      Performer.grant(performer, ability)
      Performer.grant(performer, ability)

      performer = Repo.get(Performer, performer.id)

      assert 1 == length(performer.abilities)
      assert "delete_accounts" == Enum.at(performer.abilities, 0)
    end

    test "grant different abilities to performer" do
      performer = insert(:performer)
      ability_delete = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      Performer.grant(performer, ability_delete)
      Performer.grant(performer, ability_ban)

      performer = Repo.get(Performer, performer.id)
      assert 2 == length(performer.abilities)
      assert [ability_delete.identifier] ++ [ability_ban.identifier] == performer.abilities
    end

    test "grant role to performer" do
      performer = insert(:performer)
      role = insert(:role, identifier: "admin")

      Performer.grant(performer, role)

      performer = Repo.get(Performer, performer.id) |> Repo.preload([:roles])

      assert 1 == length(performer.roles)
      assert role == Enum.at(performer.roles, 0)
    end

    test "grant role to inherited performer" do
      performer = insert(:performer)
      role = insert(:role, identifier: "admin")

      Performer.grant(%{performer: performer}, role)

      performer = Repo.get(Performer, performer.id) |> Repo.preload([:roles])

      assert 1 == length(performer.roles)
      assert role == Enum.at(performer.roles, 0)
    end

    test "grant role to inherited performer from id" do
      performer = insert(:performer)
      role = insert(:role, identifier: "admin")

      Performer.grant(%{performer_id: performer.id}, role)

      performer = Repo.get(Performer, performer.id) |> Repo.preload([:roles])

      assert 1 == length(performer.roles)
      assert role == Enum.at(performer.roles, 0)
    end

    test "grant only unique roles to performer" do
      performer = insert(:performer)
      role = insert(:role, identifier: "admin")

      Performer.grant(performer, role)
      Performer.grant(performer, role)

      performer = Repo.get(Performer, performer.id) |> Repo.preload([:roles])

      assert 1 == length(performer.roles)
      assert role == Enum.at(performer.roles, 0)
    end

    test "grant different roles to performer" do
      performer = insert(:performer)
      role_admin = insert(:role, identifier: "admin")
      role_editor = insert(:role, identifier: "editor")

      Performer.grant(performer, role_admin)
      Performer.grant(performer, role_editor)

      performer = Repo.get(Performer, performer.id) |> Repo.preload([:roles])

      assert 2 == length(performer.roles)
      assert [role_admin] ++ [role_editor] == performer.roles
    end
  end

  describe "Terminator.Performer.revoke/2" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Performer.revoke(nil, nil)
      end
    end

    test "revokes correct ability from performer" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      Performer.grant(performer, ability)
      Performer.grant(performer, ability_ban)
      performer = Repo.get(Performer, performer.id)
      assert 2 == length(performer.abilities)

      Performer.revoke(performer, ability)
      performer = Repo.get(Performer, performer.id)
      assert 1 == length(performer.abilities)
      assert "ban_accounts" == Enum.at(performer.abilities, 0)
    end

    test "revokes correct ability from inherited performer" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      Performer.grant(performer, ability)
      Performer.grant(performer, ability_ban)
      performer = Repo.get(Performer, performer.id)
      assert 2 == length(performer.abilities)

      Performer.revoke(%{performer: performer}, ability)
      performer = Repo.get(Performer, performer.id)
      assert 1 == length(performer.abilities)
      assert "ban_accounts" == Enum.at(performer.abilities, 0)
    end

    test "revokes correct ability from inherited performer from id" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      Performer.grant(performer, ability)
      Performer.grant(performer, ability_ban)
      performer = Repo.get(Performer, performer.id)
      assert 2 == length(performer.abilities)

      Performer.revoke(%{performer_id: performer.id}, ability)
      performer = Repo.get(Performer, performer.id)
      assert 1 == length(performer.abilities)
      assert "ban_accounts" == Enum.at(performer.abilities, 0)
    end

    test "revokes correct role from performer" do
      performer = insert(:performer)
      role_admin = insert(:role, identifier: "admin")
      role_editor = insert(:role, identifier: "editor")

      Performer.grant(performer, role_admin)
      Performer.grant(performer, role_editor)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:roles])
      assert 2 == length(performer.roles)

      Performer.revoke(performer, role_admin)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:roles])
      assert 1 == length(performer.roles)
      assert role_editor == Enum.at(performer.roles, 0)
    end

    test "revokes correct role from inherited performer" do
      performer = insert(:performer)
      role_admin = insert(:role, identifier: "admin")
      role_editor = insert(:role, identifier: "editor")

      Performer.grant(performer, role_admin)
      Performer.grant(performer, role_editor)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:roles])
      assert 2 == length(performer.roles)

      Performer.revoke(%{performer: performer}, role_admin)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:roles])
      assert 1 == length(performer.roles)
      assert role_editor == Enum.at(performer.roles, 0)
    end

    test "revokes correct role from inherited performer from id" do
      performer = insert(:performer)
      role_admin = insert(:role, identifier: "admin")
      role_editor = insert(:role, identifier: "editor")

      Performer.grant(performer, role_admin)
      Performer.grant(performer, role_editor)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:roles])
      assert 2 == length(performer.roles)

      Performer.revoke(%{performer_id: performer.id}, role_admin)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:roles])
      assert 1 == length(performer.roles)
      assert role_editor == Enum.at(performer.roles, 0)
    end
  end

  describe "Terminator.Performer.revoke/3" do
    test "rejects invalid revoke" do
      assert_raise ArgumentError, fn ->
        Performer.grant(nil, nil, nil)
      end
    end

    test "revokes ability from performer on struct" do
      struct = insert(:role)
      performer = insert(:performer)
      ability = insert(:ability, identifier: "view_role")

      Performer.grant(performer, ability, struct)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:entities])

      assert 1 == length(performer.entities)
      assert Terminator.has_ability?(performer, :view_role, struct)

      performer = Performer.revoke(performer, ability, struct)
      refute Terminator.has_ability?(performer, :view_role, struct)
    end

    test "revokes ability from inherited performer on struct" do
      struct = insert(:role)
      performer = insert(:performer)
      ability = insert(:ability, identifier: "view_role")

      Performer.grant(performer, ability, struct)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:entities])

      assert 1 == length(performer.entities)
      assert Terminator.has_ability?(performer, :view_role, struct)

      performer = Performer.revoke(%{performer: performer}, ability, struct)
      refute Terminator.has_ability?(performer, :view_role, struct)
    end

    test "revokes ability from inherited performer from id on struct" do
      struct = insert(:role)
      performer = insert(:performer)
      ability = insert(:ability, identifier: "view_role")

      Performer.grant(performer, ability, struct)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:entities])

      assert 1 == length(performer.entities)
      assert Terminator.has_ability?(performer, :view_role, struct)

      performer = Performer.revoke(%{performer_id: performer.id}, ability, struct)
      refute Terminator.has_ability?(performer, :view_role, struct)
    end
  end

  describe "Terminator.Performer.grant/3" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Performer.revoke(nil, nil, nil)
      end
    end

    test "grant ability to performer on struct" do
      # Can be any struct
      struct = insert(:role)
      performer = insert(:performer)
      ability = insert(:ability, identifier: "view_role")

      Performer.grant(performer, ability, struct)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:entities])

      assert 1 == length(performer.entities)
      assert Terminator.has_ability?(performer, :view_role, struct)
    end

    test "grant ability to inherited performer on struct" do
      # Can be any struct
      struct = insert(:role)
      performer = insert(:performer)
      ability = insert(:ability, identifier: "view_role")

      Performer.grant(%{performer: performer}, ability, struct)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:entities])

      assert 1 == length(performer.entities)
      assert Terminator.has_ability?(performer, :view_role, struct)
    end

    test "grant ability to inherited performer from id on struct" do
      # Can be any struct
      struct = insert(:role)
      performer = insert(:performer)
      ability = insert(:ability, identifier: "view_role")

      Performer.grant(%{performer_id: performer.id}, ability, struct)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:entities])

      assert 1 == length(performer.entities)
      assert Terminator.has_ability?(performer, :view_role, struct)
    end

    test "revokes ability to performer on struct" do
      # Can be any struct
      struct = insert(:role)
      performer = insert(:performer)
      ability = insert(:ability, identifier: "view_role")

      Performer.grant(performer, ability, struct)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:entities])

      assert 1 == length(performer.entities)
      assert Terminator.has_ability?(performer, :view_role, struct)

      Performer.revoke(performer, ability, struct)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:entities])

      assert 0 == length(performer.entities)
      refute Terminator.has_ability?(performer, :view_role, struct)
    end

    test "revokes no ability to performer on struct" do
      # Can be any struct
      struct = insert(:role)
      performer = insert(:performer)
      ability = insert(:ability, identifier: "view_role")

      Performer.revoke(performer, ability, struct)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:entities])

      assert 0 == length(performer.entities)
      refute Terminator.has_ability?(performer, :view_role, struct)
    end

    test "grants multiple abilities to performer on struct" do
      # Can be any struct
      struct = insert(:role)
      performer = insert(:performer)
      ability = insert(:ability, identifier: "view_role")
      ability_delete = insert(:ability, identifier: "delete_role")

      performer = Performer.grant(performer, ability, struct)
      performer = Performer.grant(performer, ability_delete, struct)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:entities])

      assert 1 == length(performer.entities)
      assert Terminator.has_ability?(performer, :view_role, struct)
      assert Terminator.has_ability?(performer, :delete_role, struct)
    end

    test "revokes multiple abilities to performer on struct" do
      # Can be any struct
      struct = insert(:role)
      performer = insert(:performer)
      ability = insert(:ability, identifier: "view_role")
      ability_delete = insert(:ability, identifier: "delete_role")

      performer = Performer.grant(performer, ability, struct)
      performer = Performer.grant(performer, ability_delete, struct)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:entities])

      assert 1 == length(performer.entities)
      assert Terminator.has_ability?(performer, :view_role, struct)
      assert Terminator.has_ability?(performer, :delete_role, struct)

      Performer.revoke(performer, ability_delete, struct)
      refute Terminator.has_ability?(performer, :delete_role, struct)
      assert Terminator.has_ability?(performer, :view_role, struct)
    end
  end
end
