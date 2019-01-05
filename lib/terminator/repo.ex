defmodule Terminator.Repo do
  @moduledoc """
  Ecto repository
  """

  use Ecto.Repo,
    otp_app: :terminator,
    adapter: Ecto.Adapters.Postgres
end
