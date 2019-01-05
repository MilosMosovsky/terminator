defmodule Terminator.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Terminator.Registry, [])
    ]

    children = children ++ load_repos()

    opts = [strategy: :one_for_one, name: Terminator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp load_repos do
    case Application.get_env(:terminator, :ecto_repos) do
      nil -> [Terminator.Repo]
      repos -> repos
    end
  end
end
