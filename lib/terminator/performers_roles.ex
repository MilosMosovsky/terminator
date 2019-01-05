defmodule Terminator.PerformersRoles do
  @moduledoc false

  use Ecto.Schema

  schema "terminator_performers_roles" do
    belongs_to(:performer, Terminator.Performer)
    belongs_to(:role, Terminator.Role)

    timestamps()
  end
end
