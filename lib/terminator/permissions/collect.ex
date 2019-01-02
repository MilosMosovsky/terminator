defmodule Terminator.Permissions.Collect do
  def role_abilities(performer) do
    performer.abilities
  end

  def performer_abilities(performer) do
    []
  end
end
