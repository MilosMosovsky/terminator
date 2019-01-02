# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :terminator,
  ecto_repos: [Terminator.Repo]

config :terminator, Terminator.Repo,
  username: "postgres",
  password: "postgres",
  database: "api_dev",
  hostname: "localhost"

import_config "#{Mix.env()}.exs"
