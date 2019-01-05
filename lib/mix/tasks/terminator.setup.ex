defmodule Mix.Tasks.Terminator.Setup do
  use Mix.Task

  @shortdoc "Setup terminator tables"

  def run(_argv) do
    Mix.Tasks.Ecto.Migrate.run(["-r", "Terminator.Repo"])
  end
end
