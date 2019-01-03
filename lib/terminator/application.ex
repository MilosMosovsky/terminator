defmodule Terminator.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Terminator.Registry, [])
    ]

    children = children ++ ensure_local_test_repo()

    opts = [strategy: :one_for_one, name: Terminator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp ensure_local_test_repo do
    case Mix.env() in [:test, :dev] do
      true -> Application.get_env(:terminator, :ecto_repos)
      _ -> []
    end
  end
end
