defmodule Mix.Tasks.TerminatorSetupTest do
  use ExUnit.Case
  import Mock

  test "provide a list of available terminator mix tasks" do
    with_mock Mix.Tasks.Ecto.Migrate, run: fn _params -> nil end do
      Mix.Tasks.Terminator.Setup.run([])
      assert_called(Mix.Tasks.Ecto.Migrate.run(["-r", "Terminator.Repo"]))
    end
  end
end
