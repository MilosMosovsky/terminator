defmodule Mix.Tasks.TerminatorTest do
  use ExUnit.Case

  test "provide a list of available terminator mix tasks" do
    Mix.Tasks.Terminator.run([])
    assert_received {:mix_shell, :info, ["Terminator v" <> _]}
    # assert_received {:mix_shell, :info, ["mix terminator.setup" <> _]}
  end

  test "expects no arguments" do
    assert_raise Mix.Error, fn ->
      Mix.Tasks.Ecto.run(["invalid"])
    end
  end
end
