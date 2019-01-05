defmodule Post do
  use Terminator

  def delete(performer) do
    load_and_authorize_performer(performer)

    permissions do
      has_role(:admin)
    end

    as_authorized do
      {:ok, "Authorized"}
    end
  end

  def update(performer) do
    load_and_authorize_performer(performer)

    permissions do
      has_ability(:update_post)
    end

    as_authorized do
      {:ok, "Authorized"}
    end
  end

  def no_macro(performer) do
    load_and_authorize_performer(performer)

    permissions do
      has_ability(:update_post)
    end

    case is_authorized?() do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def no_permissions(performer) do
    load_and_authorize_performer(performer)

    permissions do
    end

    case is_authorized?() do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def calculated(performer, email_confirmed) do
    load_and_authorize_performer(performer)

    permissions do
      calculated(fn _performer ->
        email_confirmed
      end)
    end

    case is_authorized?() do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def calculated_macro(performer) do
    load_and_authorize_performer(performer)

    permissions do
      calculated(:confirmed_email)
    end

    case is_authorized?() do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def confirmed_email(_performer) do
    false
  end
end

defmodule Terminator.TerminatorTest do
  use Terminator.EctoCase

  describe "Terminator.create_terminator" do
    test "loads macros" do
      functions = Post.__info__(:functions)

      assert [
               calculated: 2,
               calculated_macro: 1,
               confirmed_email: 1,
               delete: 1,
               load_and_authorize_performer: 1,
               no_macro: 1,
               no_permissions: 1,
               update: 1
             ] == functions
    end

    test "rejects no role" do
      performer = insert(:performer)

      assert {:error, "Performer is not granted to perform this action"} == Post.delete(performer)
    end

    test "rejects invalid role" do
      performer = insert(:performer)
      role = insert(:role, identifier: "editor")

      Terminator.Performer.grant(performer, role)

      assert {:error, "Performer is not granted to perform this action"} == Post.delete(performer)
    end

    test "allows role" do
      performer = insert(:performer)
      role = insert(:role, identifier: "admin")

      performer = Terminator.Performer.grant(performer, role)
      assert {:ok, "Authorized"} == Post.delete(performer)
    end

    test "rejects no abilities" do
      performer = insert(:performer)

      assert {:error, "Performer is not granted to perform this action"} == Post.update(performer)
    end

    test "rejects invalid ability" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "view_post")

      performer = Terminator.Performer.grant(performer, ability)

      assert {:error, "Performer is not granted to perform this action"} == Post.update(performer)
    end

    test "allows ability" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "update_post")

      performer = Terminator.Performer.grant(performer, ability)

      assert {:ok, "Authorized"} == Post.update(performer)
    end

    test "rejects inherited ability from role" do
      performer = insert(:performer)
      role = insert(:role, identifier: "admin", name: "Administator")
      ability = insert(:ability, identifier: "view_post")

      role = Terminator.Role.grant(role, ability)
      performer = Terminator.Performer.grant(performer, role)

      assert {:error, "Performer is not granted to perform this action"} == Post.update(performer)
    end

    test "allows inherited ability from role" do
      performer = insert(:performer)
      role = insert(:role, identifier: "admin", name: "Administator")
      ability = insert(:ability, identifier: "update_post")

      role = Terminator.Role.grant(role, ability)
      performer = Terminator.Performer.grant(performer, role)

      assert {:ok, "Authorized"} == Post.update(performer)
    end

    test "allows inherited ability from multiple roles" do
      performer = insert(:performer)
      role = insert(:role, identifier: "admin", name: "Administator")
      role_editor = insert(:role, identifier: "editor", name: "Administator")
      ability = insert(:ability, identifier: "delete_post")
      ability_update = insert(:ability, identifier: "update_post")

      role = Terminator.Role.grant(role, ability)
      role_editor = Terminator.Role.grant(role_editor, ability_update)
      performer = Terminator.Performer.grant(performer, role)
      performer = Terminator.Performer.grant(performer, role_editor)

      assert {:ok, "Authorized"} == Post.update(performer)
    end

    test "rejects ability without macro block" do
      performer = insert(:performer)

      assert_raise ArgumentError, fn ->
        Post.no_macro(performer)
      end
    end

    test "allows ability without macro block" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "update_post")

      performer = Terminator.Performer.grant(performer, ability)

      assert {:ok, "Authorized"} == Post.no_macro(performer)
    end

    test "allows ability without any required permissions" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "update_post")

      performer = Terminator.Performer.grant(performer, ability)

      assert {:ok, "Authorized"} == Post.no_permissions(performer)
    end
  end

  describe "Terminator.authorize!/1" do
    test "it evaluates empty conditions as true" do
      assert :ok == Terminator.authorize!([])
    end
  end

  describe "Terminator.load_and_store_performer/1" do
    test "allows ability to not preloaded performer from database" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "update_post")

      not_loaded_performer = %{performer_id: performer.id}
      Terminator.Performer.grant(performer, ability)

      assert {:ok, "Authorized"} == Post.update(not_loaded_performer)
    end
  end

  describe "Terminator.store_performer/1" do
    test "allows ability to performer loaded on different struct" do
      performer = insert(:performer)
      ability = insert(:ability, identifier: "update_post")

      performer = Terminator.Performer.grant(performer, ability)
      user = %{performer: performer}

      assert {:ok, "Authorized"} == Post.update(user)
    end
  end

  describe "Terminator.calculated/1" do
    test "grants calculated permissions" do
      performer = insert(:performer)
      assert {:ok, "Authorized"} == Post.calculated(performer, true)
    end

    test "rejects calculated permissions" do
      performer = insert(:performer)

      assert_raise ArgumentError, fn ->
        Post.calculated(performer, false)
      end
    end

    test "rejects macro calculated permissions" do
      performer = insert(:performer)
      assert {:ok, "Authorized"} == Post.calculated(performer, true)
    end
  end
end
