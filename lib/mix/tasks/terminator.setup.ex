defmodule Mix.Tasks.Terminator.Setup do
  use Mix.Task

  @shortdoc "Setup terminator tables"

  def run(_argv) do
    Mix.shell().info("A toolkit for data mapping and language integrated query for Elixir.")
    Mix.Tasks.Ecto.Migrate.run([])
  end
end
