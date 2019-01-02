defmodule Terminator.RegistyTest do
  use ExUnit.Case
  alias Terminator.Registry

  setup do
    :ets.delete_all_objects(Terminator.Registry)
    :ok
  end

  describe "Terminator.Registry.insert/2" do
    test "insert string item" do
      assert Registry.insert(:test_item, "John Snow")
    end

    test "insert struct item " do
      assert Registry.insert(:test_item, %{name: "John Snow"})
    end

    test "insert tuple item" do
      assert Registry.insert(:test_item, {:ok, %{name: "John Snow"}})
    end
  end

  describe "Terminator.Registry.add/2" do
    test "add array item to the ets table" do
      assert Registry.add(:test_item, :dummy)
    end
  end

  describe "Terminator.Registry.lookup/1" do
    test "lookup string item" do
      Registry.insert(:test_item, "John Snow")

      assert Registry.lookup(:test_item) == {:ok, "John Snow"}
    end

    test "lookup struct item" do
      Registry.insert(:test_item, %{name: "John Snow"})

      assert Registry.lookup(:test_item) == {:ok, %{name: "John Snow"}}
    end

    test "lookup tuple item" do
      Registry.insert(:test_item, {:ok, %{name: "John Snow"}})
      assert Registry.lookup(:test_item) == {:ok, {:ok, %{name: "John Snow"}}}
    end

    test "lookup non existing item" do
      assert Registry.lookup(:bogus_item) == {:ok, nil}
    end

    test "creates and array" do
      Registry.add(:test_item, :dummy)

      assert Registry.lookup(:test_item) == {:ok, [:dummy]}
    end

    test "insert and lookup array" do
      Registry.add(:test_item, :dummy)
      Registry.add(:test_item, :dummy2)

      assert Registry.lookup(:test_item) == {:ok, [:dummy, :dummy2]}
    end
  end
end
