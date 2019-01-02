defmodule TerminatorTest do
  use ExUnit.Case
  doctest Terminator

  test "greets the world" do
    assert Terminator.hello() == :world
  end
end
