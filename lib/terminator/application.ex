defmodule Terminator.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [

    ]

    IO.inspect("SPAWN TERMINATOR!")

    opts = [strategy: :one_for_one, name: Terminator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
