defmodule Terminator.PerformersAbilities do
  use Ecto.Schema

  schema "terminator_performers_abilities" do
    belongs_to(:performer, Terminator.Performer)
    belongs_to(:ability, Terminator.Ability)

    timestamps()
  end
end
