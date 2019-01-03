defmodule Terminator.EctoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Terminator.Repo

      import Ecto
      import Ecto.Query
      import Terminator.EctoCase
      import Terminator.Factory

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Terminator.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Terminator.Repo, {:shared, self()})
    end

    :ok
  end
end
