defmodule Terminator.RoleTest do
  use Terminator.EctoCase
  alias Terminator.Role

  setup do
    Terminator.reset_session()
    :ok
  end

  describe "Terminator.Role.changeset/2" do
    test "changeset is invalid" do
      changeset = Role.changeset(%Role{}, %{})

      refute changeset.valid?
    end

    test "changeset is valid" do
      changeset = Role.changeset(%Role{identifier: "admin", name: "Global administrator"})

      assert changeset.valid?
    end
  end

  describe "Terminator.Role.build/3" do
    test "builds changeset" do
      classic_changeset =
        Role.changeset(%Role{}, %{
          identifier: "admin",
          abilities: [],
          name: "Global administrator"
        })

      built_changeset = Role.build("admin", [], "Global administrator")

      assert built_changeset == classic_changeset
    end
  end

  describe "Terminator.Role.grant/2" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Role.grant(nil, nil)
      end
    end

    test "grant ability to role" do
      role = insert(:role, identifier: "admin", name: "Global Administrator")
      ability = insert(:ability, identifier: "delete_accounts")

      Role.grant(role, ability)

      role = Repo.get(Role, role.id)

      assert 1 == length(role.abilities)
      assert ability.identifier == Enum.at(role.abilities, 0)
    end

    test "grant unique abilities to role" do
      role = insert(:role, identifier: "admin", name: "Global Administrator")
      ability = insert(:ability, identifier: "delete_accounts")

      Role.grant(role, ability)
      Role.grant(role, ability)

      role = Repo.get(Role, role.id)

      assert 1 == length(role.abilities)
      assert ability.identifier == Enum.at(role.abilities, 0)
    end

    test "grants multiple abilities to role" do
      role = insert(:role, identifier: "admin", name: "Global Administrator")
      ability_delete = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      role = Role.grant(role, ability_delete)
      Role.grant(role, ability_ban)

      role = Repo.get(Role, role.id)

      assert 2 == length(role.abilities)
      assert assert ["delete_accounts", "ban_accounts"] == role.abilities
    end
  end

  describe "Terminator.Role.revoke/2" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Role.revoke(nil, nil)
      end
    end

    test "revokes correct ability from role" do
      role = insert(:role, identifier: "admin", name: "Global Administrator")
      ability = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      role = Role.grant(role, ability)
      role = Role.grant(role, ability_ban)

      assert 2 == length(role.abilities)

      role = Role.revoke(role, ability)

      assert "ban_accounts" == Enum.at(role.abilities, 0)
    end
  end
end
