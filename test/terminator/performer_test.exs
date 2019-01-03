defmodule Terminator.PerformerTest do
  use Terminator.EctoCase
  alias Terminator.Performer

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

      performer = Repo.get(Performer, performer.id) |> Repo.preload([:abilities])

      assert 1 == length(performer.abilities)
      assert ability == Enum.at(performer.abilities, 0)
    end

    test "grant only unique abilities to performer" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "delete_accounts")

      Performer.grant(performer, ability)
      Performer.grant(performer, ability)

      performer = Repo.get(Performer, performer.id) |> Repo.preload([:abilities])

      assert 1 == length(performer.abilities)
      assert ability == Enum.at(performer.abilities, 0)
    end

    test "grant different abilities to performer" do
      performer = insert(:performer)
      ability_delete = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      Performer.grant(performer, ability_delete)
      Performer.grant(performer, ability_ban)

      performer = Repo.get(Performer, performer.id) |> Repo.preload([:abilities])

      assert 2 == length(performer.abilities)
      assert [ability_delete] ++ [ability_ban] == performer.abilities
    end

    test "grant role to performer" do
      performer = insert(:performer)
      role = insert(:role, identifier: "admin")

      Performer.grant(performer, role)

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
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:abilities])
      assert 2 == length(performer.abilities)

      Performer.revoke(performer, ability)
      performer = Repo.get(Performer, performer.id) |> Repo.preload([:abilities])
      assert 1 == length(performer.abilities)
      assert ability_ban == Enum.at(performer.abilities, 0)
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
  end
end
