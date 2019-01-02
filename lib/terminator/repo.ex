defmodule Terminator.Repo do
  use Ecto.Repo,
    otp_app: :terminator,
    adapter: Ecto.Adapters.Postgres
end
